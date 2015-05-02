package Host;

use strict;
use warnings;
use v5.20;
use Fcntl qw(:flock SEEK_END);
use POSIX qw(strftime);

sub DEBUG { 0; };


sub do_ping {
	my $self = shift;

	`ping -c 1 $self->{addr}`;
	$self->{pings} += 1;
	$self->log_ping();

	if ($? == 0) {
		$self->{failed_pings} = 0;
	} else {
		$self->{failed_pings} += 1;
	}
}


sub new {
	my ($class, $name, $addr, $logfile) = @_;

	my $self = {
			name	=> $name,
			addr	=> $addr,
			logfile	=> $logfile,

			allowed_failed_pings	=> 2,
			failed_pings		=> 0,
			is_up			=> -1, # unknown
			log_pings		=> 0,
			old_status		=> -1, # unknown
			ping_delay		=> 30,
			pings			=> 0,
		   };

	bless($self, $class);
	return $self;
}


sub log {
	my ($self, $msg) = @_;

	my $timestr = strftime " %Y%m%d-%H%M%S", localtime;

	open my $lfh, '>>', $self->{logfile};
	flock($lfh, LOCK_EX);
	seek($lfh, 0, SEEK_END);

	print $lfh "$timestr: host($self->{name}): $msg\n";

	close $lfh;
}


sub log_statuschange {
	my $self = shift;

	my $msg = "status changed to ";
	$msg .= $self->{is_up} ? 'UP' : 'DOWN';

	$self->log($msg);
}


sub log_ping {
	my $self = shift;
	return if not $self->{log_pings};

	my $msg = "";

	if ($self->{failed_pings} == 0) {
		$msg .= "ping succeeded";
	} else {
		$msg .= "ping $self->{failed_pings}/$self->{allowed_failed_pings} failed";
	}

	$self->log($msg);
}


sub ping {
	my $self = shift;

	if (DEBUG) { $self->{log_pings} = 1; }

	# TODO: set up a SIGKILL handler for the pinger

	$self->set_initial_status();

	while (1) {
		sleep($self->{ping_delay});

		$self->do_ping();
		$self->set_status();
	}
}


sub set_initial_status {
	my $self = shift;

	$self->do_ping();
	$self->{is_up} = $self->{failed_pings} > 0 ? 0 : 1;
	$self->log_statuschange();
}


sub set_status {
	my $self = shift;

	$self->{old_status} = $self->{is_up};

	if ($self->{pings} > $self->{allowed_failed_pings}) {
		$self->{is_up} =
			$self->{failed_pings} > $self->{allowed_failed_pings} ? 0 : 1;
	}

	$self->log_statuschange() if $self->{is_up} != $self->{old_status};
}

1;
