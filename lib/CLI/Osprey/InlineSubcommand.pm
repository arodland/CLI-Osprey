package CLI::Osprey::InlineSubcommand;
use strict;
use warnings;
use Moo;

# ABSTRACT: A class to wrap coderef subcommands
# VERSION
# AUTHORITY

has 'name' => (
  is => 'ro',
  required => 1,
);

has 'desc' => (
  is => 'bare',
  reader => '_osprey_subcommand_desc',
);

has 'method' => (
  is => 'ro',
  required => 1,
);

has 'parent' => (
  is => 'rw',
  required => 1,
);

has 'argv' => (
  is => 'rw',
);

sub run {
  my ($self) = @_;
  my $method = $self->method;

  @_ = ($self->parent, @{ $self->argv });
  goto &$method;
}

no Moo;
1;
