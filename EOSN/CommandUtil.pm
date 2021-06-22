package EOSN::CommandUtil;

use utf8;
use strict;
use Date::Format qw(time2str);
use File::Slurp qw(write_file);

use parent qw(Exporter);
our @EXPORT_OK = qw(write_timestamp_log write_file_atomic);

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

sub write_file_atomic {
	my ($filename, @stuff) = @_;

	my $temp = "$filename.tmp";
	write_file ($temp, @stuff);
	return rename ($temp, $filename);
}

1;
