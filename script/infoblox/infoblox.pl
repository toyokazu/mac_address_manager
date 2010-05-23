#!/usr/bin/env perl

#use strict;
use Getopt::Std;
use YAML::Syck;

our ($opt_f);
getopt('f:');

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

# read task file
my $tasks = LoadFile($opt_f || $directory . "/tasks.yml");
# process tasks
foreach (@{$tasks}) {
  # FIXME
  my $method = $_->[0];
  my $args = $_->[1];
  $manager->$method(@{$args})
}

