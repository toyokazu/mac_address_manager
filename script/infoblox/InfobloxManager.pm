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
    print("Construct session failed: ",
      Infoblox::status_code() . ":" . Infoblox::status_detail()) . "\n";
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
  print "Fixed Address\n";
  foreach my $fixed_addr (@fixed_addrs) {
    print "mac: " . $fixed_addr->mac . "\n";
    print "ipv4addr: " . $fixed_addr->ipv4addr . "\n";
    print "comment: " . $fixed_addr->comment . "\n";
  }
}

sub fixed_addr {
  my $self = shift;
  my ($operation, $mac, $ipv4addr, $comment) = @_;

  my @fixed_addrs = $self->{session}->get(
    object => "Infoblox::DHCP::FixedAddr",
    mac => $mac,
  );
  if ($operation eq 'create' && $#fixed_addrs == -1) { # Create
    my $fixed_addr = Infoblox::DHCP::FixedAddr->new(
      mac => $mac,
      ipv4addr => $ipv4addr,
      comment => $comment
    );
    my $response = $self->{session}->add($fixed_addr)
      or print("Create new fixed_addr failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail()) . "\n";
  } elsif ($operation eq 'update') { # Update
    if ($#fixed_addrs == -1) {
      print("Cannot find any fixed_addr for updating with specified MAC address.\n");
      return -1;
    }
    $fixed_addrs[0]->ipv4addr($ipv4addr);
    $fixed_addrs[0]->comment($comment);
    my $response = $self->{session}->modify($fixed_addrs[0])
      or print("Modify fixed_addr (", $fixed_addrs[0]->mac,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail()) . "\n";
  } elsif ($operation eq 'delete') { # Delete
    if ($#fixed_addrs == -1) {
      print("Cannot find any fixed_addr for deleting with specified MAC address.\n");
      return -1;
    }
    my $response = $self->{session}->remove($fixed_addrs[0])
      or print("Delete fixed_addr (", $fixed_addrs[0]->mac,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail()) . "\n";
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
  print "Host Records:\n";
  foreach my $host_record (@host_records) {
    print "name: " . $host_record->name . "\n";
    # ipv4addr has an array of string (IPv4 address) or FixedAddr instance
    print "ipv4addr:\n";
    foreach my $ipv4addr (@{$host_record->ipv4addrs}) {
      if (ref($ipv4addr) eq "Infoblox::DHCP::FixedAddr") {
        print "  ipv4addr: " . $ipv4addr->ipv4addr . "\n";
        print "  mac: " . $ipv4addr->mac . "\n";
        print "  comment: " . $ipv4addr->comment . "\n";
      } else {
        print "  " . $ipv4addr . "\n";
      }
    }
    # ipv6addr has an array of string (IPv6 address)
    print "ipv6addr:\n";
    foreach my $ipv6addr (@{$host_record->ipv6addrs}) {
      print "  " . $ipv6addr . "\n";
    }
    print "aliases:\n";
    foreach my $alias (@{$host_record->aliases}) {
      print "  " . $alias . "\n";
    }
    print "comment: " . $host_record->comment . "\n";
  }
}

sub host_record {
  my $self = shift;
  my ($operation, $name, $ipv4addr, $ipv6addr, $mac, $aliases, $comment) = @_;
  my @host_records = $self->{session}->get(
    object => "Infoblox::DNS::Host",
    name => $name
  );
  if ($operation eq 'create' && $#host_records == -1) { # Create
    my $fixed_addr = Infoblox::DHCP::FixedAddr->new(
      mac => $mac,
      ipv4addr => $ipv4addr,
      ipv6addr => $ipv6addr,
      comment => $comment,
      configure_for_dhcp => "true"
    );
    my $host_record = Infoblox::DNS::Host->new(
      name => $name,
      ipv4addrs => [$fixed_addr],
      aliases => $aliases,
      comment => $comment
    );
    my $response = $self->{session}->add($host_record)
      or print("Create new host_record failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail()) . "\n";
  } elsif ($operation eq 'update') { # Update
    if ($#host_records == -1) {
      print("Cannot find any host_record for updating with specified hostname.\n");
      return -1;
    }
    my $fixed_addr = $host_records[0]->ipv4addrs->[0];
    if (ref($fixed_addr) eq "Infoblox::DHCP::FixedAddr") {
      $fixed_addr->mac($mac);
      $fixed_addr->ipv4addr($ipv4addr);
      $fixed_addr->comment($comment);
    } else {
      $fixed_addr = $ipv4addr;
    }
    $host_records[0]->name($name);
    $host_records[0]->ipv4addrs([$fixed_addr]);
    $host_records[0]->ipv6addrs([$ipv6addr]);
    $host_records[0]->aliases($aliases);
    $host_records[0]->comment($comment);
    my $response = $self->{session}->modify($host_records[0])
      or print("Modify host_record (", $host_records[0]->name,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail());
  } elsif ($operation eq 'delete') { # Delete
    if ($#host_records == -1) {
      print("Cannot find any host_record for deleting with specified MAC address.\n");
      return -1;
    }
    my $response = $self->{session}->remove($host_records[0])
      or print("Delete host_record (", $host_records[0]->name,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail()) . "\n";
  }
}

1;
