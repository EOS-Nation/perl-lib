package EOSN::Webpage;

# Environment Variables:
# - EOSN_WEBPAGE_WEB
# - EOSN_WEBPAGE_CONFIG
# - EOSN_WEBPAGE_LANG

# --------------------------------------------------------------------------
# Required modules

use utf8;
use strict;
use File::Slurp qw(read_file);
use YAML qw(LoadFile);
use I18N::AcceptLanguage;
use Date::Format qw(time2str);
use Date::Parse qw(str2time);
use Carp qw(confess);

# --------------------------------------------------------------------------
# Class Methods

sub new {
	my ($class) = shift;
	my ($self) = {};
	bless $self, $class;
	return $self->initialize (@_);
}

sub DESTROY {
	my ($self) = @_;

	$self->{content} = undef;
}

# --------------------------------------------------------------------------
# Private Methods

sub initialize {
	my ($self) = @_;

	$self->read_env;
	$self->read_strings;

	return $self;
}

sub webdir {
	my ($self) = @_;

	return $self->{webdir};
}

sub configdir {
	my ($self) = @_;

	return $self->{configdir};
}

sub read_env {
	my ($self) = @_;

	$self->{webdir} = $ENV{EOSN_WEBPAGE_WEB} || '/var/www/html';
	$self->{configdir} = $ENV{EOSN_WEBPAGE_CONFIG} || '/etc/page';
	$self->{default_lang} = $ENV{EOSN_WEBPAGE_LANG} || 'en';
}

sub read_strings {
	my ($self) = @_;

	my $labels = LoadFile ($self->configdir . '/language.yml');
	my %langs;

	foreach my $label (keys %$labels) {
		foreach my $lang (keys %{$$labels{$label}}) {
			$langs{$lang} = 1;
			#print sprintf ("label %20s %2s: %s\n", $label, $lang, ($$labels{$label}{$lang} || 'undef'));
		}
	}

	$self->{langs} = [sort keys %langs];
	$self->{labels} = $labels;
}

sub lang {
	my ($self, %options) = @_;

	my $env = $options{env};
	my $default_lang = $options{default_lang} || $self->{default_lang};

	my $acceptor = I18N::AcceptLanguage->new;
	my $lang = $acceptor->accepts ($$env{HTTP_ACCEPT_LANGUAGE}, [$self->langs]) || $default_lang;

	return $lang;
}

sub langs {
	my ($self) = @_;

	return @{$self->{langs}};
}

sub labels {
	my ($self) = @_;

	return $self->{labels};
}

sub label {
	my ($self, %options) = @_;

	my $lang = $options{lang} || confess "$0: lang not provided";
	my $key = $options{key} || confess "$0: key not provided";
	my $default_lang = $options{default_lang} || $self->{default_lang};
	my $labels = $self->labels;

	return $$labels{$key}{$lang} || $$labels{$key}{$default_lang} || "[$key]";
}

sub table_row {
	my ($self, %options) = @_;

	my $lang = $options{lang};
	my $key = $options{key};
	my $value = $options{value};

	return '<tr><td colspan=2> &nbsp; </td></tr>' if (! $key);
	return '<tr><td>' . $self->label (lang => $lang, key => $key) . ': &nbsp; ' . '</td><td align=right>' . $value . '</td>';
}

sub commify {
	my ($self, %options) = @_;

	my $lang = $options{lang};
	my $default_lang = $options{default_lang} || $self->{default_lang};
	my $value = $options{value};
	my $xlang = $lang || $default_lang;

	return undef if (! $value);

	my $comma = ',';
	$comma = ' ' if ($xlang eq 'fr');

	my $text = reverse $value;
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1$comma/g;
	return scalar reverse $text;
}

sub datetime {
	my ($self, %options) = @_;

	my $lang = $options{lang};
	my $unixtime = $options{unixtime};
	my $timestring = $options{timestring};

	if ($timestring) {
		 $unixtime = str2time ($timestring);
	}

	if (! $unixtime) {
		return '';
	}

	return time2str ($self->label (lang => $lang, key => 'format_datetime'), $unixtime, 'UTC');
}

sub inject_footer {
	my ($self, %options) = @_;

	my $content = $options{content};
	my $lang = $options{lang};
	my $footer_filename = $self->configdir . '/footer.html';

	if (-e $footer_filename . '.' . $lang) {
		$footer_filename = $footer_filename . '.' . $lang;
	}

	my $footer = read_file ($footer_filename, {binmode => ':utf8'});

	$content =~ s#<footer class="footer">\n(.*)</footer>\n#$footer#s;
	my $site_content = $1;
	chomp ($site_content);
	$site_content =~ s/\n/\n    /gs;  # indent every line by 4 spaces
	$content =~ s#%SITE_FOOTER%#$site_content#;

	return $content;
}

sub generate_page {
	my ($self, %options) = @_;

	my $lang = $options{lang};
	my $title = $options{title} || $self->label (lang => $lang, key => 'title');
	my $footer = $options{footer} || $self->label (lang => $lang, key => 'footer');
	my $content = $options{content};
	my $pagefile = $options{pagefile} || $self->webdir . '/res/page.html';

	my $output = read_file ($pagefile, {binmode => ':utf8'});
	$output = $self->inject_footer (content => $output, lang => $lang);

	$output =~ s/%CONTENT%/$content/;
	$output =~ s/%TITLE%/$title/g;
	$output =~ s/%FOOTER%/$footer/g;

	return $output;
}

sub error_404 {
	return [
		'404',
		[ ],
		[ '404 Not Found' ]
	];
}

1;
