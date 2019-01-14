package MyCmd::Role::Config;

use Moo::Role;

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
