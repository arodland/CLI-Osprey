package CLI::Osprey::Config;

# ABSTRACT: Hierarchical Configuration File support for CLI::Osprey
# AUTHORITY
# VERSION

use Moo::Role;


use namespace::clean;

has _config => (
    is      => 'ro',
    default => sub { {} },
);

around parse_options => sub {
    my $orig  = shift;
    my $class = $_[0];
    my ( $params, $usage ) = &$orig;

    if ( exists $params->{config} ) {

        my $config = $params->{config};

        if ( !-f $config || !-R _ ) {
            use Carp ();
            Carp::croak(
                qq[config file "$config" does not exist or is not readable\n] );
        }

        require Config::Any;
        $params->{_config} = Config::Any->load_files( {
                files           => [$config],
                use_ext         => 1,
                flatten_to_hash => 1,
            } )->{$config};
    }

    return ( $params, $usage );
};

around BUILDARGS => sub {
    my $orig   = shift;
    my $class  = $_[0];
    my $params = &$orig;

    my %_config;

    %_config = %{ $params->{_config} }
      if defined $params->{_config};

    my $meta = $params->{_meta};

    %_config
      = ( %{ $params->{parent_command}->_config->{ $params->{subcommand} } // {} }, %_config )
      if defined $params->{parent_command} && $params->{parent_command}->can( '_config' );

    $params->{_config} = \%_config;

    # this assumes a hierarchical config file, with a level for
    # each subcommand.
    my %subcommands = $class->_osprey_subcommands;
    while ( my ( $key, $value ) = each %_config ) {

	# if key is subcommand name, it's parameters for that
	# subcommand not for this command
	next if exists $subcommands{$key};
	$params->{$key} //= $value;
    }

    return $params;
};

1;

# COPYRIGHT


__END__

=head1 SYNOPSIS

  package App {

    use Moo;
    use CLI::Osprey;

    with 'CLI::Osprey::Config';

    option config => (
        is      => 'ro',
        format  => 's',
    );

    subcommand 'subcmd' => 'App::SubCmd';

    sub run {
      ...
    }

  }

  package SubCmd {

    use Moo;
    use CLI::Osprey;

    with 'CLI::Osprey::Config';

    option config => (
        is      => 'ro',
        format  => 's',
    );

    sub run {
      ...
    }

  }

  App->new_with_options->run;

=head1 DESCRIPTION

This L<Moo Role|Moo::Role> provides transparent hierarchical access to
configuration files in a program that uses L<CLI::Opsrey> to manage
command line arguments and options.

B<CLI::Osprey::Config> uses L<Config::Any> to load configuration
files, so they may be in a format of your choosing.

A command's configuration file should be hierarchical, with the top
(I<root>) layer for the command's general options, and with subsequent
nested structures for the sub-commands.

For example, take an application with two sub-commands, C<subcmd1> and
C<subcmd2>, where C<subcmd1> has it's own sub-command, C<subcmd1_1>.
Each level has its own set of options, C<a> and C<b>.  Here's a sample
top-level configurtion file (F<app.yaml>):

  a: 1
  b: 2
  subcmd1:
    a: 3
    b: 4
    subcmd1_1:
      a: 5
      b: 6
  subcmd2 :
    a: 7
    b: 8

A sub-command's configuration file should contain only the options for it
and its sub-commands, so for C<subcmd1> it'll look like this (F<subcmd1.yaml>):

  a: 9
  b: 10
  subcmd1_1 :
    a: 11
    b: 12

while for C<subcmd1_1> it'll look like this (F<subcmd1_1.yaml>)

  a: 13
  b: 14

So, if the command is invoked as

  app --config app.yaml subcmd1

C<subcmd1>'s C<a> option will be set to C<3>, while

  app subcmd1 --config subcmd1.yaml

will set it to C<9>.

Configuration files may be simultaneously specified for each layer of commands,
the most specific configuration file for a command overrides any specified before.

So,

  app --config app.yaml subcmd1 --config subcmd1.yaml

results in C<subcmd1>'s C<a> option being set to C<9>.
