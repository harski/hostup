#!/usr/bin/perl

# Copyright 2015 Tuomo Hartikainen <tth@harski.org>.
# Licensed under the 2-clause BSD license, see LICENSE for details.

use strict;
use warnings;

use v5.20;
use Getopt::Long;
use Hostup::Host;
use Hostup::Util qw(log_str);
use Readonly;

Readonly my $VERSION => "0.1";

my %opt = (
	action_help	=> 0,
	action_version	=> 0,
	config_path	=> "$ENV{HOME}/.hostsup.conf",
	logfile		=> "$ENV{HOME}/.hostsup.log",
);

GetOptions('c|config=s' => \$opt{config_path},
	   'h|help|usage!'	=> \$opt{action_help},
	   'l|log=s'	=> \$opt{logfile},
	   'V|version!'	=> \$opt{action_version},
	  ) or die("Error in command line arguments\n");


sub action_hostup {
	my $hosts_ref = load_hosts($opt{config_path});
	my $pingers_ref = start_pingers($hosts_ref);

	log_str($opt{logfile}, "hostup_service", "STARTED");

	# wait for children to die
	# TODO: add signal handler to kill children
	while () {
		my $ret = wait;
		if ($ret == -1) {
			last;
		}

		print "child '$ret' terminated\n";
	}
}


sub load_hosts {
	my ($path) = @_;

	my @hosts;

	if (-f $path) {
		open my $file, '<', $path or die $!;

		while (my $line = <$file>) {
			if ($line =~ /\A \s* host \s+ (\S+) \s+ (\S+)/xms) {
				push @hosts, Hostup::Host->new($1, $2, $opt{logfile});
			}
		}

		close $file;
	}

	return \@hosts;
}


sub print_help {
	print <<HELP_END
$0 [OPTION]...

Options:
  -c, --config CONFIG_FILE
  -h, --help, --usage
  -l, --log LOG_FILE
  -V, --version
HELP_END
}


sub print_version {
	print <<PRINT_VERSION
$0 version $VERSION
Copyright 2015 Tuomo Hartikainen <tth\@harski.org>.
Licensed under the 2-clause BSD license.
PRINT_VERSION
}


sub start_pingers {
	my $hosts_ref = shift;
	my @pingers;

	for my $host (@{$hosts_ref}) {
		my $pid = fork;

		if (not defined $pid) {
			# TODO: kill all children
			print STDERR "Fork failed, quitting\n";
			exit 1;
		} elsif ($pid == 0) {
			# child process
			$host->ping();
		} else {
			push @pingers, $pid;
		}
	}
	return \@pingers;
}


if ($opt{action_help}) {
	print_help();
} elsif ($opt{action_version}) {
	print_version();
} else {
	action_hostup();
}
