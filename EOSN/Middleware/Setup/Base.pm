package EOSN::Middleware::Setup::Base;

use utf8;
use strict;
use warnings;
use YAML qw(LoadFile);
use Carp qw(confess);

use parent qw(Plack::Middleware);

# Environment Variables:
# - EOSN_WEBPAGE_DOMAIN (use "any" to match any domain)
# - EOSN_WEBPAGE_WEB
# - EOSN_WEBPAGE_CONFIG
# - EOSN_WEBPAGE_LANG

# --------------------------------------------------------------------------
# Preparation Methods

sub prepare_app {
	my ($self) = @_;

	$self->read_env;
	$self->read_strings;
	$self->read_globals;
}

sub read_env {
	my ($self) = @_;

	my $config = {};
	my $domain = $ENV{EOSN_WEBPAGE_DOMAIN} || confess "missing env EOSN_WEBPAGE_DOMAIN";

	$$config{$domain}{ServerName} = $domain;
	$$config{$domain}{DocumentRoot} = $ENV{EOSN_WEBPAGE_WEB} || confess "missing env EOSN_WEBPAGE_WEB";
	$$config{$domain}{ConfigDir} = $ENV{EOSN_WEBPAGE_CONFIG} || confess "missing env EOSN_WEBPAGE_CONFIG";
	$$config{$domain}{DefaultLang} = $ENV{EOSN_WEBPAGE_LANG} || confess "missing env EOSN_WEBPAGE_LANG";
	$$config{$domain}{CustomLogFile} = "/var/log/httpd/$domain-access.log";
	$$config{$domain}{CustomLogType} = 'combined';

	$self->{config} = $config;
}

sub read_strings {
	my ($self) = @_;

	foreach my $host (keys %{$self->{config}}) {
		my $config = $self->{config}->{$host};
		my $configdir = $$config{ConfigDir};

		my $labels = LoadFile ($configdir . '/language.yml');
		my %langs;

		foreach my $label (keys %$labels) {
			foreach my $lang (keys %{$$labels{$label}}) {
				$langs{$lang} = 1;
				#print sprintf ("label %20s %2s: %s\n", $label, $lang, ($$labels{$label}{$lang} || 'undef'));
			}
		}

		$$config{langs} = [sort keys %langs];
		$$config{labels} = $labels;
	}
}

sub read_globals {
	my ($self) = @_;

	# for sublcass use only
}

# --------------------------------------------------------------------------
# Call Methods

sub call {
	my ($self, $env) = @_;

	my $host = $self->host (env => $env);
	my $config = $self->{config}->{$host} || $self->{config}->{any};

	$$env{'eosn.app'} = $config;

	return $self->app->($env);
}

sub host {
	my ($self, %options) = @_;

	# http host without port number

	my $env = $options{env};
	my $host = $$env{HTTP_HOST};
	if ($host) {
		$host =~ s/:\d+$//;
	}

	return $host;
}

1;
