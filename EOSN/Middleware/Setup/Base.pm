package EOSN::Middleware::Setup::Base;

use utf8;
use strict;
use warnings;

use parent qw(Plack::Middleware);

# --------------------------------------------------------------------------
# Subroutines

sub prepare_app {
	my ($self) = @_;

	my $config = {};
	my $domain = $ENV{EOSN_WEBPAGE_DOMAIN} || die "missing env EOSN_WEBPAGE_DOMAIN";

	$$config{$domain}{ServerName} = $domain;
	$$config{$domain}{DocumentRoot} = $ENV{EOSN_WEBPAGE_WEB} || die "missing env EOSN_WEBPAGE_WEB";
	$$config{$domain}{ConfigDir} = $ENV{EOSN_WEBPAGE_CONFIG} || "/var/www/$domain";
	$$config{$domain}{DefaultLang} = $ENV{EOSN_WEBPAGE_LANG} || die "missing env EOSN_WEBPAGE_LANG";
	$$config{$domain}{CustomLogFile} = "/var/log/httpd/$domain-access.log";
	$$config{$domain}{CustomLogType} = 'combined';

	$self->{config} = $config;
}

sub call {
	my ($self, $env) = @_;

	my $host = $self->host (env => $env);
	my $config = $self->{config}->{$host};

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
