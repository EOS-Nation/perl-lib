package EOSN::Middleware::XForwardedFor;
# Same as Plack::Middleware::XForwardedFor
# ABSTRACT: Plack middleware to handle X-Forwarded-For headers
$Plack::Middleware::XForwardedFor::VERSION = '0.172050';
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(trust);
use Net::IP qw();
 
sub prepare_app {
  my $self = shift;
 
  if (my $trust = $self->trust) {
    my @trust = map { Net::IP->new($_) } ref($trust) ? @$trust : ($trust);
    $self->trust(\@trust);
  }
}
 
sub call {
  my ($self, $env) = @_;
 
  my @forward =
    map { s/^::ffff://; $_ }
    (split(/,\s*/, ($env->{HTTP_X_FORWARDED_FOR} || '')));
 
  if (@forward) {
    my $addr = $env->{REMOTE_ADDR};
    $addr =~ s/^::ffff://;
 
    if (my $trust = $self->trust) {
    ADDR: {
        if (my $next = pop @forward) {
          foreach my $netmask (@$trust) {
            my $ip = Net::IP->new($addr) or redo ADDR;
            if ($netmask->overlaps($ip)) {
              $addr = $next;
              redo ADDR;
            }
          }
        }
      }
    }
    else {    # trust everything, so use first in list
      $addr = shift @forward;
    }
    $env->{REMOTE_ADDR} = $addr;
  }
 
  $self->app->($env);
}

