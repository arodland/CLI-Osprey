package MyCmd::Role::Options;

use Moo::Role;

sub _extract_options {

    my ( $class, $config, $params ) = shift;

    # this assumes a hierarchical config file, with a level for
    # each subcommand.
    my %subcommands = $class->_osprey_subcommands;
    while ( my ( $key, $value ) = each %$config ) {

	# if key is subcommand name, it's parameters for that
	# subcommand not for this command
	next if exists $subcommands{$key};
	$params->{$key} //= $value;
    }

}

1;
