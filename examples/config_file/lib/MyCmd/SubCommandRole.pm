package MyCmd::SubCommandRole;

use Moo::Role;

has _config => (
    is      => 'ro',
    default => sub { {} },
);

around new_with_options => sub {
    my ( $orig, $class, %params ) = @_;
    $params{_config} = $params{parent_command}->_config->{$params{subcommand}} // {};
    return $class->$orig( %{ $params{_config} }, %params );
};

1;

