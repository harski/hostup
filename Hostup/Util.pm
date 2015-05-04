# Copyright 2015 Tuomo Hartikainen <tth@harski.org>.
# Licensed under the 2-clause BSD license, see LICENSE for details.

package Hostup::Util;

use strict;
use warnings;
use v5.20;
use Fcntl qw(:flock SEEK_END);
use POSIX qw(strftime);
use Exporter qw(import);

our @EXPORT_OK = qw(log_str);


sub log_str {
	my ($file, $sender, $msg) = @_;

	my $timestr = strftime " %Y%m%d-%H%M%S", localtime;

	open my $lfh, '>>', $file;
	flock($lfh, LOCK_EX);
	seek($lfh, 0, SEEK_END);

	print $lfh "$timestr: host($sender): $msg\n";

	close $lfh;
}

1;
