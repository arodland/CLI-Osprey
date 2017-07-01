package CLI::Osprey;
use strict;
use warnings;

# ABSTRACT: MooX::Options + MooX::Cmd + Sanity
# VERSION
# AUTHORITY

use Carp 'croak';
use Module::Runtime 'use_module';

my @OPTIONS_ATTRIBUTES = qw(
  option option_name format short repeatable negativable spacer_before spacer_after doc long_doc order hidden
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
    prefer_commandline => 1,
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

  unless (defined $attributes{option}) {
    ($attributes{option} = $name) =~ tr/_/-/;
  }
  my $ret = {};
  for (@OPTIONS_ATTRIBUTES) {
    $ret->{$_} = $attributes{$_} if exists $attributes{$_};
  }
  return $ret;
}

1;
__END__

=head1 SYNOPSIS

in Hello.pm

    package Hello;
    use Moo;
    use CLI::Osprey;

    option 'message' => (
        is => 'ro',
        format => 's',
        doc => 'The message to display',
        default => 'Hello world!',
    );

    sub run {
        my ($self) = @_;
        print $self->message, "\n";
    }

In hello.pl

    use Hello;
    Hello->new_with_options->run;

=head1 DESCRIPTION

CLI::Osprey is a module to assist in writing commandline applications with M*
OO modules (Moose, Moo, Mo). With it, you structure your app as one or more
modules, which get instantiated with the commandline arguments as attributes.
Arguments are parsed using L<Getopt::Long::Descriptive>, and both long and
short help messages as well as complete manual pages are automatically
generated. An app can be a single command with options, or have sub-commands
(like C<git>). Sub-commands can be defined as modules (with options of their
own) or as simple coderefs.

=head2 Differences from MooX::Options

Osprey is deliberately similar to L<MooX::Options>, and porting an app that
uses MooX::Options to Osprey should be fairly simple in most cases. However
there are a few important differences:

=over 4

=item *

Osprey is pure-perl, without any mandatory XS dependencies, meaning it can be
used in fatpacked scripts, and other situations where you may need to run on
diverse machines, where a C compiler and control over the ennvironment aren't
guaranteed.

=item *

Osprey's support for sub-commands is built-in from the beginning. We think this
makes for a better experience than MooX::Options + MooX::Cmd.

=item *

While MooX::Options requires an option's primary name to be the same as the
attribute that holds it, and MooX::Cmd derives a sub-command's name from the
name of the module that implements it, Osprey separates these, so that Perl
identifier naming conventions don't dictate your command line interface.

=item *

Osprey doesn't use an automatic module finder (like L<Module::Pluggable>) to
locate modules for sub-commands; their names are given explicitly. This small
amount of additional typing gives you more control and less fragility.

=back

There are also a few things MooX::Options has that Osprey lacks. While they may
be added in the future, I haven't seen the need yet. Currently known missing
feeatures are JSON options, C<config_from_file> support, C<autosplit>, and C<autorange>.

For JSON support, you can use a coercion on the attribute, turning it from a
string to a ref via C<decode_json>.

To default an app's options from a config file, you may want to do something
like this in your script file:

    use JSON 'decode_json';
    use Path::Tiny;

    MyApp->new_with_options(
        map decode_json(path($_)->slurp),
        grep -f,
        "$ENV{HOME}/.myapprc"
    )->run;

Provided that C<prefer_commandline> is true (which is the default), any
options in C<.myapprc> will be used as defaults if that file exists, but will
still be overrideable from the commandline.

=head1 IMPORTED METHODS

The following methods, will be imported into a class that uses CLI::Osprey:

=head2 new_with_options

Parses commandline arguments, validates them, and calls the C<new> method with
the resulting parameters. Any parameters passed to C<new_with_options> will
also be passed to C<new>; the C<prefer_commandline> import option controls
which overrides which.

=head2 option

The C<option> keyword acts like C<has> (and accepts all of the arguments that
C<has> does), but also registers the attribute as a commandline option. See
L</OPTION PARAMETERS> for usage.

=head2 osprey_usage($code, @messages)

Displays a short usage message, the same as if the app was invoked with the
C<-h> option. Also displays the lines of text in C<@messages> if any are
passed. If C<$code> is passed a defined value, exits with that as a status.

=head2 osprey_help($code)

Displays a more substantial usage message, the same as if the app was invoked
with the C<--help> option. If C<$code> is passed a defined value, exits with
that as a status.

=head2 osprey_man

Displays a manual page for the app, containing long descriptive text (if
provided) about each command and option, then exits.

=begin comment

osprey_man has parameters, the first one is for internal usage only and the
second one is obscure... just ignore them until I sort it out.

=end comment

=head1 IMPORT PARAMETERS

The parameters to C<use CLI::Osprey> serve two roles: to customize Osprey's
behavior, and to provide information about the app and its options for use in
the usage messages. They are:

=head2 abbreviate

Default: true.

If C<abbreviate> is set to a true value, then long options can be abbreviated to
the point of uniqueness. That is, C<--long-option-name> can be called as
C<--lon> as long as there are no other options starting with those letters. An
option can always be called by its full name, even if it is a prefix of some
longer option's name. If C<abbreviate> is false, options must always be called
by their full names (or by a defined short name).

=head2 added_order

Default: true.

If C<added_order> is set to a true value, then two options with the same
C<order> (or none at all) will appear in the help text in the same order as
their C<option> keywords were executed. If it is false, they will appear in
alphabetical order instead.

=head2 getopt_options

Default: C<['require_order']>.

Contains a list of options to control option parsing behavior (see
L<Getopt::Long/"Configuring Getopt::Long">). Note, however, that many of these
are not helpful with Osprey, and that using C<permute> will likely break
subcommands entirely. MooX::Options calls this parameter C<flavour>.

=head2 prefer_commandline

Default: true.

If true, command-line options override key/value pairs passed to
C<new_with_options>. If false, the reverse is true.

=head2 protect_argv

Default: false.

If true, the C<@ARGV> array will be localized for the duration of
C<new_with_options>, and will be left in the same state after option parsing as
it was before. If false, the C<@ARGV> array will be modified by option parsing,
removing any recognized options, values, and subcommands, and leaving behind
any positional parameters or anything after and including a C<--> separator.

=head2 usage_string

Default: C<"USAGE: $program_name %o">

Provides the header of the usage message printed in response to the C<-h>
option or an error in option processing. The format of the string is described
in L<Getopt::Long::Descriptive/"$usage_desc">.

=head1 THANKS

This module is based heavily on code from L<MooX::Options> and takes strong
inspiration from L<MooX::Cmd> and L<MooX::Options::Actions>. Thanks to
celogeek, Jens Reshack, Getty, Tom Bloor, and all contributors to those
modules. Thanks to mst for prodding me to do this. Thanks Grinnz for helping
me update my dzillage.

=cut
