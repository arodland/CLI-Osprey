package MyCmd;
use Moo;

use CLI::Osprey;

option 'message' => (
    is      => 'lazy',
    format  => 's',
    doc     => 'The message to display',
    default => 'Hello World',
);

option 'config' => (
    is     => 'rw',
    format => 's',
    short  => 'f',
    doc    => 'config file',
);

with 'MyCmd::CommandRole';

subcommand yell => __PACKAGE__ . '::Yell';

sub run {
    my ( $self ) = @_;
    print $self->message, "\n";
}

1;

