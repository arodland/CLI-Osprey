package CLI::Osprey::Descriptive::Usage;

use strict;
use warnings;
use Moo;

use overload (
  q{""} => "text",
);

use Getopt::Long::Descriptive::Usage ();

# ABSTRACT: Produce usage information for CLI::Osprey apps
# VERSION
# AUTHORITY

my %format_doc = (
  s => { short => "string", long => "string" },
  i => { short => "int"   , long => "integer" },
  o => { short => "int"   , long => "integer (dec/hex/bin/oct)" },
  f => { short => "num"   , long => "number" },
);

has 'options' => (
  is => 'ro',
);

has 'leader_text' => (
  is => 'ro',
);

has 'target' => (
  is => 'ro',
  predicate => 1,
);

has 'prog_name' => (
  is => 'ro',
  predicate => 1,
);

sub sub_commands_text {
  my ($self) = @_;

  if ($self->has_target && (my %subcommands = $self->target->_osprey_subcommands)) {
    return "", "SUB COMMANDS AVAILABLE: ", join(", ", sort keys %subcommands), "";
  }
  return;
}

sub describe_opt {
  my ($self, $opt, $length) = @_;

  if ($opt->{desc} eq 'spacer') {
    return '';
  }

  my $name = my $attr_name = $opt->{name};

  my $option_attrs;

  if ($self->has_target) {
    my %options = $self->target->_osprey_options;
    $option_attrs = $options{$attr_name};
    $name = $option_attrs->{option} if defined $option_attrs->{option};
  }


  my ($short, $format) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/;

  my $array;
  if (defined $format && $format =~ s/\@$//) {
    $array = 1;
  }

  my $format_doc_str = $format_doc{$format}{$length} if defined $format;
  my $spec;

  if ($short) {
    $spec = "-$short|";
  }

  if (length($name) > 1) {
    $spec .= "--$name";
  } else {
    $spec .= "-$name";
  }

  if (defined $format_doc_str) {
    $spec .= " $format_doc_str";
  }

  if (defined $option_attrs && !$option_attrs->{required}) {
    $spec = "[$spec]";
  }

  if ($array) {
    $spec .= "...";
  }

  if ($length eq 'long') {
    $spec .= " " . (defined($option_attrs->{long_doc}) ? $option_attrs->{long_doc} : $opt->{desc});
  }

  return $spec;
}

sub text {
  my ($self) = @_;

  my $getopt_options = $self->options;

  my @out;
  for my $opt (@$getopt_options) {
    push @out, $self->describe_opt($opt, 'short');
  }

  return join("\n", $self->leader_text, "", @out, $self->sub_commands_text);
}

sub option_help {
  my ($self) = @_;

  my $getopt_options = $self->options;
  my @out;
  for my $opt (@$getopt_options) {
    push @out, $self->describe_opt($opt, 'long');
  }

  return join("\n", $self->leader_text, "", @out, $self->sub_commands_text);
}

1;
