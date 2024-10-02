package EOSN::App::Base;

# --------------------------------------------------------------------------
# Required modules

use utf8;
use strict;
use warnings;
use Plack::Request;
use File::Slurp qw(read_file);
use I18N::AcceptLanguage;
use Date::Format qw(time2str);
use Date::Parse qw(str2time);
use Carp qw(confess);

use parent qw(Plack::Component);

# --------------------------------------------------------------------------
# Public Methods

sub prepare_app {
	my ($self) = @_;

	# do nothing

	return $self;
}

sub call {
	my ($self, $env) = @_;

	$self->{env} = $env;

	my $request = Plack::Request->new ($env);
	$self->{request} = $request;

	my $uri = $request->path_info;
	$self->{uri} = $uri;

	my $config = $$env{'eosn.app'};
	$self->{config} = $config;

	my $lang = $self->setup_lang (env => $env);
	$self->{lang} = $lang;

	$self->run;
}

sub run {
	my ($self) = @_;

	# do nothing
}

sub request {
	my ($self) = @_;

	return $self->{request};
}

sub env {
	my ($self) = @_;

	return $self->{env};
}

sub uri {
	my ($self) = @_;

	return $self->{uri};
}

sub config {
	my ($self) = @_;

	return $self->{config};
}

sub lang {
	my ($self) = @_;

	return $self->{lang};
}

sub default_lang {
	my ($self) = @_;

	return $self->{config}{DefaultLang} || confess "DefaultLang not configured";
}

sub webdir {
	my ($self) = @_;

	return $self->{config}{DocumentRoot} || confess "DocumentRoot not configured";
}

sub configdir {
	my ($self) = @_;

	return $self->{config}{ConfigDir} || confess "ConfigDir not configured";
}

sub langs {
	my ($self) = @_;

	return @{$self->{config}{langs}};
}

sub labels {
	my ($self) = @_;

	return $self->{config}{labels};
}

sub setup_lang {
	my ($self, %options) = @_;

	my $env = $options{env};
	my $default_lang = $options{default_lang} || $self->default_lang;

	my $acceptor = I18N::AcceptLanguage->new;
	my $lang = $acceptor->accepts ($$env{HTTP_ACCEPT_LANGUAGE}, [$self->langs]) || $default_lang;

	return $lang;
}

sub label {
	my ($self, %options) = @_;

	my $lang = $options{lang} || confess "$0: lang not provided";
	my $key = $options{key} || confess "$0: key not provided";
	my $default_lang = $options{default_lang} || $self->default_lang;
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
	my $default_lang = $options{default_lang} || $self->default_lang;
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

sub network {
	my ($self) = @_;

	my $network = $self->{request}->headers->header ('X-Network') || 'Unknown';
	$network =~ s/[^a-zA-Z0-9-_]//g;

	return $network;
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
	my $network = $self->network;
	my $network_config = $options{network_config};

	my $output = read_file ($pagefile, {binmode => ':utf8'});
	$output = $self->inject_footer (content => $output, lang => $lang);

	$output =~ s/%CONTENT%/$content/;
	$output =~ s/%TITLE%/$title/g;
	$output =~ s/%FOOTER%/$footer/g;

	if ($network) {
		$output =~ s/%NETWORK%/$network/g;
		$output =~ s/%NETWORK_TITLE%/$$network_config{title}/g;
	}

	return $output;
}

# --------------------------------------------------------------------------
# Public Error Methods

sub error_404 {
	return [
		'404',
		[ 'Content-Type' => 'text/plain' ],
		[ "404 Not Found\n" ]
	];
}

1;
