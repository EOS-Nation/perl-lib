package EOSN::FindDirs;

use utf8;
use strict;
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

sub find_dirs_notdot {
	my (@dirs) = @_;

	our @directories;

	find (sub {
		return if (! -d $_);
		return if ($_ =~ /^\./);

		my $x = $File::Find::name;
		$x =~ s#^\./##;
		push (@directories, $x);
	}, @dirs);

	return @directories;
}

1;
