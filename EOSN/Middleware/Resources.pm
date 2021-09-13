package EOSN::Middleware::Resources;

# Based on Plack::Middleware::Static;

use utf8;
use strict;
use warnings;
use Plack::App::File;
use Plack::Util::Accessor qw(encoding content_type);

use parent qw(Plack::Middleware);

# --------------------------------------------------------------------------
# Subroutines

sub call {
	my ($self, $env) = @_;

	my $res = $self->_handle_static ($env);
	if ($res && not ($res->[0] == 404)) {
		return $res;
	}

	return $self->app->($env);
}

sub _handle_static {
	my ($self, $env) = @_;

	my $path = $env->{PATH_INFO};
	if ($path !~ m#^/res/#) {
		return undef;
	}

	my $root = $$env{'eosn.app'}{DocumentRoot} || return undef;
	return Plack::App::File->new ({ root => $root, encoding => $self->encoding, content_type => $self->content_type })->call ($env);
}

1;
