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

has 'parent_command' => (
  is => 'rw',
);

has 'argv' => (
  is => 'rw',
);

sub new_with_options {
  my ($self, %args) = @_;
  $self->parent_command($args{ parent_command });
  $self->argv([ @ARGV ]);
  return $self;
}

sub run {
  my ($self) = @_;
  my $cmd = $self->parent_command;
  my $method = $self->method;

  @_ = ($self->parent_command, @{ $self->argv });
  goto &$method;
}

no Moo;
1;
