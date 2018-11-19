package MyCmd::SubCommandRole;

use Moo::Role;

has _config => (
    is      => 'ro',
    default => sub { {} },
);

around new_with_options => sub {
    my ( $orig, $class, %params ) = @_;

    my $_config = $params{_config} = $params{parent_command}->_config->{$params{subcommand}} // {};

    # this assumes a hierarchical config file, with a level for
    # each subcommand.
    my %subcommands = $class->_osprey_subcommands;
    while ( my ( $key, $value ) = each %$_config ) {

        # if key is subcommand name, it's parameters for that
        # subcommand not for this command
        next if exists $subcommands{$key};
        $params{$key} //= $value;
    }

    return $class->$orig( %params );
};

1;

