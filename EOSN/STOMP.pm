package EOSN::STOMP;

# --------------------------------------------------------------------------
# Required modules

use utf8;
use strict;
use Carp;
use Net::Stomp;
use Exporter;

use parent qw (Exporter);
our @EXPORT_OK = qw (do_connect_stomp);

# --------------------------------------------------------------------------
# Subroutines

sub do_connect_stomp {
	my ($vhost, $user, $password, $host, $port) = @_;

	if (! $vhost) {
		croak "No database specified";
	}

	my $env_prefix = "STOMP_CONNECTION_" . uc($vhost);
	my $env_user = "${env_prefix}_USER";
	my $env_pass = "${env_prefix}_PASS";
	my $env_host = "${env_prefix}_HOST";
	my $env_port = "${env_prefix}_PORT";

	if (! defined $user) {
		$user = $ENV{$env_user} || die "$0: $env_user is not defined";
	}

	if (! defined $password) {
		$password = $ENV{$env_pass} || die "$0: $env_pass is not defined";
	}

	if (! defined $host) {
		$host = $ENV{$env_host} || die "$0: $env_host is not defined";
	}

	if (! defined $port) {
		$port = $ENV{$env_port} || 61613;
	}

	my $stomp = Net::Stomp->new ({
		hostname => $host,
		port => $port
	});

	$stomp->connect ({
		host => $vhost,
		login => $user,
		passcode => $password
	});

	return $stomp;
}

1;
