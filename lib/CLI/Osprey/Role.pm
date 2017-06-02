package CLI::Osprey::Role;
use strict;
use warnings;
use Carp 'croak';
use Getopt::Long::Descriptive;
use CLI::Osprey::InlineSubcommand ();

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
    ($options->{$a}{order} || 9999) <=> ($options->{$b}{order} || 9999)
    || ($config->{added_order} ? ($options->{$a}{added_order} <=> $options->{$b}{added_order}) : 0)
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

has 'parent_command' => (
  is => 'ro',
);

has 'invoked_as' => (
  is => 'ro',
);

sub new_with_options {
  my ($class, %params) = @_;
  my %config = $class->_osprey_config;

  local @ARGV = @ARGV if $config{protect_argv};

  if (!defined $params{invoked_as}) {
    $params{invoked_as} = Getopt::Long::Descriptive::prog_name();
  }

  my ($parsed_params, $usage) = $class->parse_options(%params);

  if ($parsed_params->{h}) {
    return $class->osprey_usage(1, $usage);
  } elsif ($parsed_params->{help}) {
    return $class->osprey_help(1, $usage);
  } elsif ($parsed_params->{man}) {
    return $class->osprey_man($usage);
  }

  my %merged_params;
  if ($config{prefer_commandline}) {
    %merged_params = (%$parsed_params, %params);
  } else {
    %merged_params = (%params, %$parsed_params);
  }

  my %subcommands = $class->_osprey_subcommands;
  my ($subcommand_name, $subcommand_class);
  if (%subcommands && @ARGV) {
    $subcommand_name = shift @ARGV; # Remove it so the subcommand sees only options
    $subcommand_class = $subcommands{$subcommand_name};
    if (ref $subcommand_class eq 'CODE') {
      $subcommand_class = CLI::Osprey::InlineSubcommand->new(
        name => $subcommand_name,
        method => $subcommand_class,
      );
    } elsif (!defined $subcommand_class) {
      croak "Unknown subcommand $ARGV[0] (available: ". join(", ", sort keys %subcommands)  .")";
    }
  }

  my $self;
  unless (eval { $self = $class->new(%merged_params); 1 }) {
    if ($@ =~ /^Attribute \((.*?)\) is required/) {
      print STDERR "$1 is missing\n";
    } elsif ($@ =~ /^Missing required arguments: (.*) at /) {
      my @missing_required = split /,\s/, $1;
      print STDERR "$_ is missing\n" for @missing_required;
    } elsif ($@ =~ /^(.*?) required/) {
      print STDERR "$1 is missing\n";
    } elsif ($@ =~ /^isa check .*?failed: /) {
      print STDERR substr($@, index($@, ':') + 2);
    } else {
      print STDERR $@;
    }
    return $class->options_usage(1, $usage);
  }

  if ($subcommand_class) {
    return $subcommand_class->new_with_options(%params, parent_command => $self, invoked_as => "$params{invoked_as} $subcommand_name");
  } else {
    return $self;
  }
}

sub parse_options {
  my ($class, %params) = @_;

  my %options = $class->_osprey_options;
  my %config = $class->_osprey_config;

  my ($options, $abbreviations) = _osprey_prepare_options(\%options, \%config);
  @ARGV = _osprey_fix_argv(\%options, $abbreviations);

  my @getopt_options = qw(require_order);

  push @getopt_options, @{$config{getopt_options}} if defined $config{getopt_options};

  my $prog_name = $params{invoked_as};

  my $usage_str = $config{usage_string};
  $usage_str = "USAGE: $prog_name %o" unless defined $usage_str;

  my ($opt, $usage) = describe_options(
    $usage_str,
    @$options,
    [],
    [ 'h', "show a short help message" ],
    [ 'help', "show a long help message" ],
    [ 'man', "show the manual" ],
    { getopt_conf => \@getopt_options },
  );

  $usage->{prog_name} = $prog_name;
  $usage->{target} = $class;

  if ($usage->{should_die}) {
    return $class->osprey_usage(1, $usage);
  }

  my %parsed_params;

  for my $name (keys %options) {
    $parsed_params{$name} = $opt->$name();
  }

  for my $name (qw(h help man)) {
    my $val = $opt->$name();
    $parsed_params{$name} = $val if defined $val;
  }

  return \%parsed_params, $usage;

}

1;
