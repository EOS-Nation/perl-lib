package EOSN::FindDirs;

use utf8;
use strict;
use File::Find;

use parent qw(Exporter);
our @EXPORT_OK = qw(find_dirs);

# --------------------------------------------------------------------------
# Subroutines

sub find_dirs {
	my (@dirs) = @_;

	our @directories;

	find (\&wanted, @dirs);

	sub wanted {
		return if (! -d $_);

		my $x = $File::Find::name;
		$x =~ s#^\./##;
		push (@directories, $x);
	}

	return @directories;
}

1;
