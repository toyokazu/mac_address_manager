package InfobloxManager;

use strict;
use Infoblox;

sub new {
  my $class = shift;
  my ($server, $username, $password) = @_;
  my $self = {
    server => $server,
    username => $username,
    password => $password,
    session => undef,
  };
  bless $self, $class;
}

sub start_session {
  my $self = shift;
  #Create a session to the Infoblox appliance
  $self->{session} = Infoblox::Session->new(
    master => $self->{server}, #appliance host ip
    username => $self->{username}, #appliance user login
    password => $self->{password}, #appliance password
    timeout => 60
  );
  unless ($self->{session}) {
    print("Construct session failed: \n",
      Infoblox::status_code() . ":" . Infoblox::status_detail() . "\n");
    return -1;
  }
  print "Session (", $self->{server}, ") created successfully\n";
}

sub find_fixed_addr {
  my $self = shift;
  my ($mac, $ipv4addr) = @_;
  my @fixed_addrs = ();
  if ($mac ne undef) {
    @fixed_addrs = $self->{session}->search(
      object => "Infoblox::DHCP::FixedAddr",
      mac => $mac
    );
  } elsif ($ipv4addr ne undef) {
    @fixed_addrs = $self->{session}->search(
      object => "Infoblox::DHCP::FixedAddr",
      ipv4addr => $ipv4addr
    );
  }
  if ($#fixed_addrs == -1) {
    print("Cannot find any fixed_addr with specified MAC or IP address (" . $mac . "/" . $ipv4addr . ").\n");
    return -1;
  }
  $self->print_fixed_addrs(\@fixed_addrs);
}

sub print_fixed_addrs {
  my $self = shift;
  my ($fixed_addrs) = @_;

  print "Fixed Address\n";
  foreach my $fixed_addr (@{$fixed_addrs}) {
    print "  mac: " . $fixed_addr->{mac} . "\n";
    print "  ipv4addr: " . $fixed_addr->{ipv4addr} . "\n";
    print "  configure_for_dhcp: " . $fixed_addr->{configure_for_dhcp} . "\n";
    print "  comment: " . $fixed_addr->{comment} . "\n";
  }
}

sub fixed_addr {
  my $self = shift;
  my ($operation, $mac, $ipv4addr, $configure_for_dhcp, $comment) = @_;

  my @fixed_addrs = $self->{session}->get(
    object => "Infoblox::DHCP::FixedAddr",
    mac => $mac,
  );
  if ($operation eq 'create' && $#fixed_addrs == -1) { # Create
    my $fixed_addr = Infoblox::DHCP::FixedAddr->new(
      mac => $mac,
      ipv4addr => $ipv4addr,
      configure_for_dhcp => $configure_for_dhcp,
      comment => $comment
    );
    my $response = $self->{session}->add($fixed_addr)
      or print("Create new fixed_addr failed: \n",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail() . "\n");
  } elsif ($operation eq 'update') { # Update
    if ($#fixed_addrs == -1) {
      print("Cannot find any fixed_addr for updating with specified MAC address.\n");
      return -1;
    }
    $fixed_addrs[0]->ipv4addr($ipv4addr);
    $fixed_addrs[0]->comment($comment);
    my $response = $self->{session}->modify($fixed_addrs[0])
      or print("Modify fixed_addr (", $fixed_addrs[0]->mac,") failed: \n",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail() . "\n");
  } elsif ($operation eq 'delete') { # Delete
    if ($#fixed_addrs == -1) {
      print("Cannot find any fixed_addr for deleting with specified MAC address.\n");
      return -1;
    }
    my $response = $self->{session}->remove($fixed_addrs[0])
      or print("Delete fixed_addr (", $fixed_addrs[0]->mac,") failed: \n",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail() . "\n");
  }
}

sub find_host_record {
  my $self = shift;
  my ($name, $ipv4addr, $ipv6addr) = @_;
  my @host_records = ();
  if ($name ne undef) {
    @host_records = $self->{session}->search(
      object => "Infoblox::DNS::Host",
      name => $name
    );
  } elsif ($ipv4addr ne undef) {
    @host_records = $self->{session}->search(
      object => "Infoblox::DNS::Host",
      ipv4addr => $ipv4addr
    );
  } elsif ($ipv6addr ne undef) {
    @host_records = $self->{session}->search(
      object => "Infoblox::DNS::Host",
      ipv6addr => $ipv6addr
    );
  }
  if ($#host_records == -1) {
    print("Cannot find any host_record with specified hostname, IPv4 or IPv6  address.\n");
    return -1;
  }
  $self->print_host_records(\@host_records);
}

sub print_host_records {
  my $self = shift;
  my ($host_records) = @_;
  
  print "Host Records:\n";
  foreach my $host_record (@{$host_records}) {
    print "name: " . $host_record->{name} . "\n";
    # ipv4addr has an array of string (IPv4 address) or FixedAddr instance
    print "ipv4addrs:\n";
    foreach my $ipv4addr (@{$host_record->{ipv4addrs}}) {
      print "  --\n";
      if (ref($ipv4addr) eq "Infoblox::DHCP::FixedAddr") {
        print "  ipv4addr: " . $ipv4addr->{ipv4addr} . "\n";
        print "  mac: " . $ipv4addr->{mac} . "\n";
        print "  configure_for_dhcp: " . $ipv4addr->{configure_for_dhcp} . "\n";
        print "  comment: " . $ipv4addr->{comment} . "\n";
      } else {
        print "  " . $ipv4addr . "\n";
      }
    }
    # ipv6addr has an array of string (IPv6 address)
    print "ipv6addrs:\n";
    foreach my $ipv6addr (@{$host_record->{ipv6addrs}}) {
      print "  " . $ipv6addr . "\n";
    }
    print "aliases:\n";
    foreach my $alias (@{$host_record->{aliases}}) {
      print "  " . $alias . "\n";
    }
    print "comment: " . $host_record->{comment} . "\n";
  }
}

sub host_record {
  my $self = shift;
  my ($operation, $name, $ipv4addr, $ipv6addr, $mac, $configure_for_dhcp, $aliases, $comment) = @_;
  # normalize attributes
  my $domain = ".cse.kyoto-su.ac.jp";
  my $fqdn = $name . $domain;
  my $aliases = $self->add_domain_to_aliases($aliases, $domain);
  my @host_records = $self->{session}->get(
    object => "Infoblox::DNS::Host",
    name => $fqdn
  );
  if ($operation eq 'create') { # Create
    if ($#host_records >= 0) { # Already exists error
      print("Cannot create new entry. Host record with specifyed hostname is already exists.\n");
      return -1;
    }
    my $ipv4addrs = [];
    if ($ipv4addr ne "") {
      my $fixed_addr = Infoblox::DHCP::FixedAddr->new(
        mac => $mac,
        ipv4addr => $ipv4addr,
        configure_for_dhcp => $configure_for_dhcp,
        comment => $comment
      );
      $ipv4addrs = [$fixed_addr];
    }
    my $host_record = Infoblox::DNS::Host->new(
      name => $fqdn,
      ipv4addrs => $ipv4addrs,
      ipv6addrs => ['::1'], # FIXME
      aliases => $aliases,
      comment => $comment
    );
    # for debug
    #$self->print_host_records([$host_record]);
    my $response = $self->{session}->add($host_record)
      or print("Create new host_record failed: \n",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail() . "\n");
    # FIXME
    # hack for create host record bug (?)
    # If ipv6addrs = [], Session->add() request fails the following error.
    # 1012:A host record requires at least one IP Address.
    # So thus, once register new entry with '::1' address then update
    # the entry with the proper ipv6addrs value.
    $host_record->ipv6addrs($self->to_array_ref($ipv6addr));
    # for debug
    #$self->print_host_records([$host_record]);
    my $response = $self->{session}->modify($host_record)
      or print("Modify new host_record failed: \n",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail() . "\n");
  } elsif ($operation eq 'update') { # Update
    if ($#host_records == -1) {
      print("Cannot find any host_record for updating with specified hostname.\n");
      return -1;
    }
    my $ipv4addrs = [];
    if ($ipv4addr ne "") {
      my $fixed_addr = $host_records[0]->ipv4addrs->[0];
      if (ref($fixed_addr) eq "Infoblox::DHCP::FixedAddr") {
        $fixed_addr->mac($mac);
        $fixed_addr->ipv4addr($ipv4addr);
        $fixed_addr->configure_for_dhcp($configure_for_dhcp);
        $fixed_addr->comment($comment);
      } else {
        $fixed_addr = Infoblox::DHCP::FixedAddr->new(
          mac => $mac,
          ipv4addr => $ipv4addr,
          configure_for_dhcp => $configure_for_dhcp,
          comment => $comment
        );
      }
      $ipv4addrs = [$fixed_addr];
    }
    $host_records[0]->name($fqdn);
    $host_records[0]->ipv4addrs($ipv4addrs);
    $host_records[0]->ipv6addrs($self->to_array_ref($ipv6addr));
    $host_records[0]->aliases($aliases);
    $host_records[0]->comment($comment);
    # for debug
    #$self->print_host_records(\@host_records);
    my $response = $self->{session}->modify($host_records[0])
      or print("Modify host_record (", $host_records[0]->name,") failed: \n",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail() . "\n");
  } elsif ($operation eq 'delete') { # Delete
    if ($#host_records == -1) {
      print("Cannot find any host_record for deleting with specified MAC address.\n");
      return -1;
    }
    my $response = $self->{session}->remove($host_records[0])
      or print("Delete host_record (", $host_records[0]->name,") failed: \n",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail() . "\n");
  }
}

sub add_domain_to_aliases {
  my $self = shift;
  my ($aliases, $domain) = @_;

  my $results = [];
  foreach my $alias (@{$aliases}) {
    push @{$results}, $alias . $domain;
  }
  return $results;
}

sub to_array_ref {
  my $self = shift;
  my ($value) = @_;

  if ($value eq "") {
    return [];
  }
  return [$value];
}

1;
