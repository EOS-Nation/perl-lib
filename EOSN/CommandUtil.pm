package EOSN::CommandUtil;

use utf8;
use strict;
use Date::Format qw(time2str);
use File::Slurp qw(read_file write_file read_dir);
use File::Find;

use parent qw(Exporter);
our @EXPORT_OK = qw(write_timestamp_log find_dirs write_file_atomic clean_old_files);

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

sub write_file_atomic {
	my ($filename, @stuff) = @_;

	my $temp = "$filename.tmp";
	write_file ($temp, @stuff);
	rename ($temp, $filename);
}

sub clean_old_files {
	my (%options) = @_;

	my $dir = $options{dir} || die;
	my $days = $options{days} || die;
	my $message = $options{message} || 'clean old files';

	write_timestamp_log ("$message starting");

	my @files = read_dir ($dir);
	foreach my $file (sort @files) {
		next if (! -f "$dir/$file");
		my $mtime = (stat ("$dir/$file"))[9];
		my $age = sprintf ("%.1f", (time - $mtime) / 3600 / 24);

		if ($age > $days) {
			write_timestamp_log ("remove file=<$file> age=<$age days>");
			unlink ("$dir/$file");
		}
	}

	write_timestamp_log ("$message done");
}

1;
