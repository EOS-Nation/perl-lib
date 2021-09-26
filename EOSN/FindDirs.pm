package EOSN::FindDirs;

# --------------------------------------------------------------------------
# Required modules

use utf8;
use strict;
use warnings;
use File::Find;

use parent qw(Exporter);
our @EXPORT_OK = qw(find_dirs find_dirs_notdot);

# --------------------------------------------------------------------------
# Subroutines

sub find_dirs {
	my (@dirs) = @_;

	our @directories;

	find (sub {
		return if (! -d $_);

		my $x = $File::Find::name;
		$x =~ s#^\./##;
		push (@directories, $x);
	}, @dirs);

	return @directories;
}

# assumes any parent directory from where we start does
# not also include a 'dot'

sub find_dirs_notdot {
	my (@dirs) = @_;

	our @directories;

	find (sub {
		return if (! -d $_);

		my $x = $File::Find::name;
		$x =~ s#^\./##;

		return if ($x =~ m#/\.#);

		push (@directories, $x);
	}, @dirs);

	return @directories;
}

1;
