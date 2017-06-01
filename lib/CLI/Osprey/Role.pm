package CLI::Osprey::Role;
use strict;
use warnings;
use Carp 'croak';

sub _osprey_option_to_getopt {
  my ($name, %attributes) = @_;
  my $getopt = join('|', grep defined, ($name, $attributes{short}));
  $getopt .= '+' if $attributes{repeatable} && !defined $attributes{format};
  $getopt .= '!' if $attributes{negativable};
  $getopt .= '=' . $attributes{format} if defined $attributes{format};
  $getopt .= '@' if $attributes{repeatable} && defined $attributes{format};
  return $getopt;
}

sub _osprey_prepare_options {
  my ($options, $config) = @_;

  my @getopt;
  my %abbreviations;
  my %fullnames;

  my @order = sort {
    $options->{$a}{order} <=> $options->{$b}{order}
    || ($config->{added_order} ? $options->{$a}{added_order} <=> $options->{$b}{added_order} : 0)
    || $a cmp $b
  } keys %$options;

  for my $option (@order) {
    my %attributes = %{ $options->{$option} };

    push @{ $fullnames{ $attributes{option} } }, $option;
  }

  for my $name (keys %fullnames) {
    if (@{ $fullnames{$name} } > 1) {
      croak "Multiple option attributes named $name: [@{ $fullnames{$name} }]";
    }
  }

  for my $option (@order) {
    my %attributes = %{ $options->{$option} };

    my $name = $attributes{option};
    my $doc = $attributes{doc};
    $doc = "no documentation for $name" unless defined $doc;

    push @getopt, [] if $attributes{spacer_before};
    push @getopt, [ _osprey_option_to_getopt($name, %attributes), $doc, ($attributes{hidden} ? { hidden => 1} : ()) ];
    push @getopt, [] if $attributes{spacer_after};

    push @{ $abbreviations{$name} }, $option;

    # If we allow abbreviating long option names, an option can be called by any prefix of its name,
    # unless that prefix is an option name itself. Ambiguous cases (an abbreviation is a prefix of
    # multiple option names) are handled later in _osprey_fix_argv.
    if ($config->{abbreviate}) {
      for my $len (1 .. length($name) - 1) {
        my $abbreviated = substr $name, 0, $len;
        push @{ $abbreviations{$abbreviated} }, $name unless exists $fullnames{$abbreviated};
      }
    }
  }

  return \@getopt, \%abbreviations;
}

sub _osprey_fix_argv {
  my ($options, $abbreviations) = @_;

  my @new_argv;

  while (defined( my $arg = shift @ARGV )) {
    # As soon as we find a -- or a non-option word, stop processing and leave everything
    # from there onwards in ARGV as either positional args or a subcommand.
    if ($arg eq '--' or $arg !~ /^-/) {
      push @new_argv, $arg, @ARGV;
      last;
    }

    my ($arg_name_with_dash, $arg_value) = split /=/, $arg, 2;
    unshift @ARGV, $arg_value if defined $arg_value;

    my ($dash, $negative, $arg_name_without_dash)
      = $arg_name_with_dash =~ /^(-+)(no\-)?(.+)$/;

    my $option_name = $abbreviations->{$arg_name_without_dash};
    if (defined $option_name) {
      if (@$option_name == 1) {
        $option_name = $option_name->[0];
      } else {
        # TODO: can't we produce a warning saying that it's ambiguous and which options conflict?
        $option_name = undef;
      }
    }

    my $arg_name = ($dash || '') . ($negative || '');
    if (defined $option_name) {
      $arg_name .= $option_name;
    } else {
      $arg_name .= $arg_name_without_dash;
    }

    push @new_argv, $arg_name;
    if (defined $option_name && $options->{$option_name}{format}) {
      push @new_argv, shift @ARGV;
    }
  }

  return @new_argv;
}

use Moo::Role;

requires qw(_osprey_config _osprey_options _osprey_subcommands);

sub new_with_options {
  # placeholder
}

sub parse_options {
  my ($class, %params) = @_;

  my %options = $class->_osprey_options;
  my %config = $class->_osprey_config;

  my ($options, $abbreviations) = _osprey_prepare_options(\%options, \%config);
  local @ARGV = @ARGV if $config{protect_argv};
  @ARGV = _osprey_fix_argv(\%options, $abbreviations);

  return @ARGV;
}

1;
