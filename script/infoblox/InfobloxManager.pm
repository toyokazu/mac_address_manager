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
      Infoblox::status_code() . ":" . Infoblox::status_detail());
    return -1;
  }
  print "Session (", $self->{server}, ") created successfully\n";
}

sub fixed_addr {
  my $self = shift;
  my ($operation, $mac_addr, $ipv4_addr, $comment) = @_;

  my @fixed_addrs = $self->{session}->get(
    object => "Infoblox::DHCP::FixedAddr",
    mac => $mac_addr,
  );
  if ($operation == 'create' && $#fixed_addrs == -1) { # Create
    my $fixed_addr = Infoblox::DHCP::FixedAddr->new(
      mac => $mac_addr,
      ipv4addr => $ipv4_addr,
      comment => $comment,
    );
    my $response = $self->{session}->add($fixed_addr)
      or print("Create new fixed_addr failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail());
  } elsif ($operation == 'update') { # Update
    if ($#fixed_addrs == -1) {
      print("Cannot find any fixed_addr for updating with specified MAC address.");
      return -1;
    }
    $fixed_addrs[0]->ipv4addr($ipv4_addr);
    $fixed_addrs[0]->comment($comment);
    my $response = $self->{session}->modify($fixed_addrs[0])
      or print("Modify fixed_addr (", $fixed_addrs[0]->mac,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail());
  } elsif ($operation == 'delete') { # Delete
    if ($#fixed_addrs == -1) {
      print("Cannot find any fixed_addr for deleting with specified MAC address.");
      return -1;
    }
    my $response = $self->{session}->remove($fixed_addrs[0])
      or print("Delete fixed_addr (", $fixed_addrs[0]->mac,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail());
  }
}

sub host_record {
  my $self = shift;
  my ($operation, $hostname, $ipv4_addr, $aliases, $comment) = @_;
  my @host_records = $self->{session}->get(
    object => "Infoblox::DNS::Host",
    name => $hostname,
    view => "default"
  );
  if ($operation == 'create' && $#host_records == -1) { # Create
    my $host_record = Infoblox::DNS::Host->new(
      host => $hostname,
      ipv4addr => $ipv4_addr,
      aliases => $aliases,
      comment => $comment,
      view => "default"
    );
    my $response = $self->{session}->add($host_record)
      or print("Create new host_record failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail());
  } elsif ($operation == 'update') { # Update
    if ($#host_records == -1) {
      print("Cannot find any host_record for updating with specified MAC address.");
      return -1;
    }
    $host_records[0]->name($hostname);
    $host_records[0]->ipv4addr($ipv4_addr);
    $host_records[0]->aliases($aliases);
    $host_records[0]->comment($comment);
    my $response = $self->{session}->modify($host_records[0])
      or print("Modify host_record (", $host_records[0]->name,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail());
  } elsif ($operation == 'delete') { # Delete
    if ($#host_records == -1) {
      print("Cannot find any host_record for deleting with specified MAC address.");
      return -1;
    }
    my $response = $self->{session}->remove($host_records[0])
      or print("Delete host_record (", $host_records[0]->name,") failed: ",
      $self->{session}->status_code() . ":" . $self->{session}->status_detail());
  }
}

1;
