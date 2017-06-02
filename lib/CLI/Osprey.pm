package CLI::Osprey;
use strict;
use warnings;

# ABSTRACT: MooX::Options + MooX::Cmd + Sanity
# VERSION
# AUTHORITY

use Carp 'croak';
use Module::Runtime 'use_module';

my @OPTIONS_ATTRIBUTES = qw(
  option option_name format short repeatable negativable doc long_doc order hidden
);

sub import {
  my (undef, @import_options) = @_;
  my $target = caller;

  for my $method (qw(with around has)) {
    next if $target->can($method);
    croak "Can't find the method '$method' in package '$target'. CLI::Osprey requires a Role::Tiny-compatible object system like Moo or Moose.";
  }

  my $with = $target->can('with');
  my $around = $target->can('around');
  my $has = $target->can('has');

  my @target_isa = do { no strict 'refs'; @{"${target}::ISA"} };
  
  if (@target_isa) { # not in a role
    eval "package $target;\n" . q{
      sub _osprey_options {
        my $class = shift;
        return $class->maybe::next::method(@_);
      }

      sub _osprey_config {
        my $class = shift;
        return $class->maybe::next::method(@_);
      }

      sub _osprey_subcommands {
        my $class = shift;
        return $class->maybe::next::method(@_);
      }
      1;
    } || croak($@);
  }

  my $osprey_config = {
    preserve_argv => 1,
    abbreviate => 1,
    @import_options,
  };

  $around->(_osprey_config => sub {
    my ($orig, $self) = (shift, shift);
    return $self->$orig(@_), %$osprey_config;
  });

  my $options_data = { };
  my $subcommands = { };

  my $apply_modifiers = sub {
    return if $target->can('new_with_options');
    $with->('CLI::Osprey::Role');
    $around->(_osprey_options => sub {
      my ($orig, $self) = (shift, shift);
      return $self->$orig(@_), %$options_data;
    });
    $around->(_osprey_subcommands => sub {
      my ($orig, $self) = (shift, shift);
      return $self->$orig(@_), %$subcommands;
    });
  };

  my $added_order = 0;

  my $option = sub {
    my ($name, %attributes) = @_;

    $has->($name => _non_option_attributes(%attributes));
    $options_data->{$name} = _option_attributes($name, added_order => ++$added_order, %attributes);
    $apply_modifiers->();
  };

  my $subcommand = sub {
    my ($name, $module) = @_;
    use_module($module) unless ref($module) eq 'CODE';

    $subcommands->{$name} = $module;
    $apply_modifiers->();
  };

  if (my $info = $Role::Tiny::INFO{$target}) {
    $info->{not_methods}{$option} = $option;
    $info->{not_methods}{$subcommand} = $subcommand;
  }

  {
    no strict 'refs';
    *{"${target}::option"} = $option;
    *{"${target}::subcommand"} = $subcommand;
  }

  $apply_modifiers->();

  return;
}

sub _non_option_attributes {
  my (%attributes) = @_;
  my %filter_out;
  @filter_out{@OPTIONS_ATTRIBUTES} = ();
  return map {
    $_ => $attributes{$_}
  } grep {
    !exists $filter_out{$_}
  } keys %attributes;
}

sub _option_attributes {
  my ($name, %attributes) = @_;

  $attributes{option} = $name unless defined $attributes{option};
  my $ret = {};
  for (@OPTIONS_ATTRIBUTES) {
    $ret->{$_} = $attributes{$_} if exists $attributes{$_};
  }
  return $ret;
}

1;
