#!/usr/bin/perl

# Copyright 2015 Tuomo Hartikainen <tth@harski.org>.
# Licensed under the 2-clause BSD license, see LICENSE for details.

use strict;
use warnings;

use Getopt::Long;
use Hostup::Host;
use Hostup::Util qw(log_str);

my %opt = (
	config_path	=> "$ENV{HOME}/.hostsup.conf",
	logfile		=> "$ENV{HOME}/.hostsup.log",
);

#GetOptions('c|config=s' => %opt{'config_path'})
#	or die("Error in command line arguments\n");


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


my $hosts_ref = load_hosts($opt{config_path});
my $pingers_ref = start_pingers($hosts_ref);

log_str($opt{logfile}, "hostup_service", "STARTED");

# wait for children to die
# TODO: add signal handler to kill children
while (-1 == wait) {}
