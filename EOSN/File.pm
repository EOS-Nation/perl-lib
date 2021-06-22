package EOSN::File;

# --------------------------------------------------------------------------
# Required modules

use utf8;
use strict;
use File::Slurp qw(write_file);

use parent qw(Exporter);
our @EXPORT_OK = qw(write_file_atomic);

# --------------------------------------------------------------------------
# Subroutines

sub write_file_atomic {
	my ($filename, @stuff) = @_;

	my $temp = "$filename.tmp";
	write_file ($temp, @stuff);
	return rename ($temp, $filename);
}

1;
