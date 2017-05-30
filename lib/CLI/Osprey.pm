package CLI::Osprey;
use strict;
use warnings;

# ABSTRACT: MooX::Options + MooX::Cmd + Sanity
# VERSION
# AUTHORITY

use Carp 'croak';
use Sub::Quote 'quote_sub';

sub import {
  my (undef, @import_options) = @_;
  my $target = caller;

  for my $method (qw(with around has)) {
    next if $target->can($method);
    croak "Can't find the method $method in $target! CLI::Osprey requires a Role::Tiny-compatible object system like Moo or Moose.";
  }

  my $with = $target->can('with');
  my $around = $target->can('around');
  my $has = $target->can('has');

  my @target_isa = do { no strict 'refs'; @{"${target}::ISA"} };
  
  if (@target_isa) { # not in a role
    eval "package $target;\n" . q{
      sub _options_data {
        my ($class, @meta) = @_;
        return $class->maybe::next::method(@meta);
      }

      sub _options_config {
        my ($class, @params) = @_;
        return $class->maybe::next::method(@params);
      }
      1;
    } || croak($@);
  }

  my $options_config = {
    test => 'foo',
  };

  $around->(_options_config => sub {
    my ($orig, $self) = (shift, shift);
    return $self->$orig(@_), %$options_config;
  });

  my $options_data = {
    test => 'bar',
  }

  my $apply_modifiers = sub {
    return if $target->can('new_with_options');
    $with->('CLI::Osprey::Role::Cmd');
    $around->(_options_data => sub {
      my ($orig, $self) = (shift, shift);
      return $self->$orig(@_), %$options_data;
    });
  };

  my $option = sub {
    my ($name, %attributes) = @_;

    $has->($name => _filter_attributes(%attributes));
    $options_data->{$name} = _filter_options(%attributes);
    $apply_modifiers->();
  };

  if (my $info = $Role::Tiny::INFO{$target}) {
    $info->{not_methods}{$option} = $option;
  }

  { no strict 'refs'; *{"${target}::option"} = $option; }

  $apply_modifiers->();

  return;
}

1;
