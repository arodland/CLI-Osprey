package MyCmd;
use Moo;

use CLI::Osprey;

option 'message' => (
    is      => 'ro',
    format  => 's',
    doc     => 'The message to display',
    default => 'Hello World',
);

option 'config' => (
    is     => 'ro',
    format => 's',
    short  => 'f',
    doc    => 'config file',
);

with 'MyCmd::Role::Config';

subcommand yell => __PACKAGE__ . '::Yell';

sub run {
    my ( $self ) = @_;
    $self->message;
}

1;

