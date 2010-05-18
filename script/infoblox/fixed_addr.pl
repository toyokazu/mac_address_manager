#!/usr/bin/env perl

use Getopt::Std;
use strict;
use Infoblox;

getopt('4:6:c:CDm:s:u:Up:');

#Create a session to the Infoblox appliance
my $session = Infoblox::Session->new(
  master => $opt_s, #appliance host ip
  #master => "192.168.1.2", #appliance host ip
  username => $opt_u, #appliance user login
  #username => "admin", #appliance user login
  password => $opt_p, #appliance password
  #password => "infoblox" #appliance password
  timeout => 60
);
unless ($session) {
  die("Construct session failed: ",
    Infoblox::status_code() . ":" . Infoblox::status_detail());
}
print "Session (", $opt_s, ") created successfully\n";
my @fixed_addrs = $session->get(
  object => "Infoblox::DHCP::FixedAddr",
  mac => $opt_m,
);
if ($opt_C && $#fixed_addrs == -1) { # Create
  my $fixed_addr = Infoblox::DHCP::FixedAddr->new(
    mac => $opt_m,
    ipv4addr => $opt_4,
    comment => $opt_c,
  );
  #Submit for addition
  my $response = $session->add($fixed_addr)
    or die("Create new entry failed: ",
      $session->status_code() . ":" . $session->status_detail());
} elsif ($opt_U) { # Update
  if ($#fixed_addrs == -1) {
    die("Cannot find any entry for updating with specified MAC address.");
  }
  $fixed_addrs[0]->ipv4addr($opt_4);
  $fixed_addrs[0]->comment($opt_c);
  my $response = $session->modify($fixed_addrs[0])
    or die("Modify entry (", $fixed_addrs[0]->mac,") failed: ",
      $session->status_code() . ":" . $session->status_detail());
} elsif ($opt_D) { # Delete
  if ($#fixed_addrs == -1) {
    die("Cannot find any entry for deleting with specified MAC address.");
  }
  my $response = $session->remove($fixed_addrs[0])
    or die("Delete entry (", $fixed_addrs[0]->mac,") failed: ",
      $session->status_code() . ":" . $session->status_detail());
}
