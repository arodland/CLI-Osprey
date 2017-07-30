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
    return $ENV{COLUMNS} if exists $ENV{COLUMNS};
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
        my $desc = $subcommands{$name}->can('_osprey_subcommand_doc') && $subcommands{$name}->_osprey_subcommand_doc;
        if (defined $desc) {
          push @out, $self->wrap(
            sprintf("%*s  %s", -$maxlen, $name, $subcommands{$name}->_osprey_subcommand_doc),
            " " x ($maxlen + 2)
          );
        } else {
          push @out, $name;
        }
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
  my ($self, $opt) = @_;

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

  my $format_doc;
  if (defined $format) {
    if (defined $option_attrs->{format_doc}) {
      $format_doc = {
        short => $option_attrs->{format_doc},
        long => $option_attrs->{format_doc},
      };
    } else {
      $format_doc = $format_doc{$format};
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

  my ($shortspec, $longspec) = ($spec, $spec);
  if (defined $option_attrs && !$option_attrs->{required}) {
    $shortspec = "[$shortspec]";
  }
  if ($array) {
    $shortspec .= "...";
  }

  if (defined $format_doc) {
    $shortspec .= " $format_doc->{short}";
    $longspec .= " $format_doc->{long}";
  }

  return {
    short => $shortspec,
    long => $longspec,
    doc => defined($option_attrs->{long_doc}) ? $option_attrs->{long_doc} : $opt->{desc},
  };
}

sub describe_options {
  my ($self) = @_;

  return map $self->describe_opt($_), @{ $self->options };
}

sub header {
  my ($self) = @_;

  my @descs = $self->describe_options;

  my $option_text = join "\n", $self->wrap(
    join(" ", map $_->{short}, @descs),
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

  my @descs = $self->describe_options;

  my $maxlen = maxlen(map $_->{long}, @descs);

  my @out = map {
    $self->wrap(
      sprintf("%*s  %s", -$maxlen, $_->{long}, $_->{doc}),
      " " x ($maxlen + 2),
    )
  } @descs;

  return join("\n", $self->header, $self->sub_commands_text('long'), @out);
}

1;
