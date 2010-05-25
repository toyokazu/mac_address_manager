#!/usr/bin/env perl

#use strict;
use Getopt::Std;
use YAML::Syck;

our ($opt_f, $opt_F, $opt_h, $opt_H, $opt_i, $opt_m);
getopt('f:Fh:Hi:m:');
# f: file name of the task file (task.yml)
# F: search FixedAddress
# h: search key (hostname)
# H: search HostRecord
# i: search key (IP Address)
# m: search key (MAC Address)

BEGIN {
  use File::Spec::Functions qw(rel2abs);
  use File::Basename qw(dirname);

  my $path   = rel2abs( $0 );
  our $directory = dirname( $path );
}

use lib $directory;
use InfobloxManager;

# read config
my $config = LoadFile($directory . "/config.yml");

# setup session
my $manager = InfobloxManager->new($config->{'server'}, $config->{'username'}, $config->{'password'});
if ($manager->start_session == -1) {
  die("An error occurred during session creation.");
}

if ($opt_F) {
  $manager->find_fixed_addr($opt_m);
  exit;
}
if ($opt_H) {
  $manager->find_host_record($opt_h, $opt_i);
  exit;
}

# read task file
my $tasks = LoadFile($opt_f || $directory . "/tasks.yml");
# process tasks
foreach (@{$tasks}) {
  # FIXME
  my $method = $_->[0];
  my $args = $_->[1];
  $manager->$method(@{$args})
}

