package EOSN::Log;

# --------------------------------------------------------------------------
# Required modules

use utf8;
use strict;
use warnings;
use Date::Format qw(time2str);

use parent qw(Exporter);
our @EXPORT_OK = qw(write_timestamp_log);

# --------------------------------------------------------------------------
# Subroutines

sub write_timestamp_log {
	my ($key, $value) = @_;

	my $log = $key || 'no message';

	if (defined $value) {
		$log = "$key: $value";
	}

	chomp ($log);

	if ($ENV{INVOCATION_ID}) {
		# running under systemd
		$| = 1;
		print sprintf ("%s\n", $log);
	} else {
		print sprintf ("%s: %s\n", time2str ("%Y-%m-%d %X", time), $log);
	}
}

1;
