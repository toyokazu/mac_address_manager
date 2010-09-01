#!/usr/bin/env perl

# Examples:
# search Host Record with hostname
# % ./script/infoblox/infoblox.pl -H -h telecon1
#
# search Host Record with IPv4 address
# % ./script/infoblox/infoblox.pl -H -4 133.101.56.74
#
# search Fixed Address with MAC address
# % ./script/infoblox/infoblox.pl -F -m 54:42:49:23:d3:4f

#use strict;
use Getopt::Std;
use YAML::Syck;

BEGIN {
  use File::Spec::Functions qw(rel2abs);
  use File::Basename qw(dirname);

  my $path   = rel2abs( $0 );
  our $directory = dirname( $path );
}

use lib $directory;
use InfobloxManager;

our %opts;
getopts('4:6:f:Fh:Hm:', \%opts);
# 4: search key (IPv4 Address)
# 6: search key (IPv6 Address)
# f: file name of the task file (task.yml)
# F: search FixedAddress
# h: search key (hostname)
# H: search HostRecord
# m: search key (MAC Address)

# read config
my $config = LoadFile($directory . "/config.yml");

# setup session
my $manager = InfobloxManager->new($config->{'server'}, $config->{'username'}, $config->{'password'});
if ($manager->start_session == -1) {
  die("An error occurred during session creation.");
}

if ($opts{"F"}) {
  $manager->find_fixed_addr($opts{"m"}, $opts{"4"}, "true", $opts{"6"});
  exit;
}
if ($opts{"H"}) {
  $manager->find_host_record($opts{"h"}, $opts{"4"}, $opts{"6"});
  exit;
}

# read task file
my $tasks = LoadFile($opts{"f"} || $directory . "/tasks.yml");
# process tasks
foreach (@{$tasks}) {
  # FIXME
  my $method = $_->[0];
  my $args = $_->[1];
  $manager->$method(@{$args})
}

