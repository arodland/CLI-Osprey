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

has 'width' => (
  is => 'ro',
  default => sub {
    return $ENV{CLI_OSPREY_OVERRIDE_WIDTH} if exists $ENV{CLI_OSPREY_OVERRIDE_WIDTH};
    return $ENV{COLS} if exists $ENV{COLS};
    return 80;
  },
);

sub wrap {
  my ($self, $in, $prefix) = @_;

  my $width = $self->width;
  return $in if $width <= 0;

  my @out;
  my $line = "";

  while ($in =~ /(\s*)(\S+)/g) {
    my ($space, $nonspace) = ($1, $2);
    if (length($line) + length($space) + length($nonspace) <= $width) {
      $line .= $space . $nonspace;
    } else {
      while (length($nonspace)) {
        push @out, $line;
        $line = $prefix;
        $line .= substr($nonspace, 0, $width - length($line), '');
      }
    }
  }
  push @out, $line if length($line);
  return @out;
}

sub maxlen {
  my $max = 0;
  for (@_) {
    $max = length($_) if length($_) > $max;
  }
  return $max;
}

sub sub_commands_text {
  my ($self, $length) = @_;

  if ($self->has_target && (my %subcommands = $self->target->_osprey_subcommands)) {
    if ($length eq 'long') {
      my $maxlen = maxlen(keys %subcommands);

      my @out;
      push @out, "";
      push @out, "Subcommands available:";

      for my $name (sort keys %subcommands) {
        push @out, $self->wrap(
          sprintf("%*s  %s", -$maxlen, $name, "TODO: description"),
          " " x ($maxlen + 2)
        );
      }
      push @out, "";

      return @out;
    } else {
      return "",
      $self->wrap(
        "Subcommands available: " . join(" | ", sort keys %subcommands),
        length("Subcommands available: ")
      );
    }
  }
  return;
}

sub describe_opt {
  my ($self, $opt, $length) = @_;

  if ($opt->{desc} eq 'spacer') {
    return;
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

  my $format_doc_str;
  if (defined $format) {
    if (defined $option_attrs->{format_doc}) {
      $format_doc_str = $option_attrs->{format_doc};
    } else {
      $format_doc_str = $format_doc{$format}{$length};
    }
  }

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

  if ($length eq 'short') {
    if (defined $option_attrs && !$option_attrs->{required}) {
      $spec = "[$spec]";
    }

    if ($array) {
      $spec .= "...";
    }
  }

  if ($length eq 'long') {
    return ($spec, defined($option_attrs->{long_doc}) ? $option_attrs->{long_doc} : $opt->{desc});
  } else {
    return $spec;
  }
}

sub header {
  my ($self) = @_;

  my $getopt_options = $self->options;

  my @descs;
  for my $opt (@$getopt_options) {
    if ($opt->{desc} ne 'spacer' && length($opt->{name}) > 1) {
      push @descs, $self->describe_opt($opt, 'short');
    }
  }

  my $option_text = join "\n", $self->wrap(
    join(" ", @descs),
    "  ",
  );

  my $text = $self->leader_text;
  $text =~ s/\Q[long options...]/$option_text/;

  return $text;
}

sub text {
  my ($self) = @_;

  return join "\n", $self->header, $self->sub_commands_text('short');
}

sub option_help {
  my ($self) = @_;

  my $getopt_options = $self->options;

  my @descs;
  for my $opt (@$getopt_options) {
    push @descs, [ $self->describe_opt($opt, 'long') ] unless $opt->{desc} eq 'spacer';
  }
  my $maxlen = maxlen(map $_->[0], @descs);

  my @out = map {
    $self->wrap(
      sprintf("%*s  %s", -$maxlen, $_->[0], $_->[1]),
      " " x ($maxlen + 2),
    )
  } @descs;

  return join("\n", $self->header, $self->sub_commands_text('long'), @out);
}

1;
