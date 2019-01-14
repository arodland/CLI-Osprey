package MyCmd::Yell;
use Moo;
use CLI::Osprey;

with 'MyCmd::Role::SubCommand';

subcommand quietly => __PACKAGE__ . '::Quietly';

option loudness => (
    is      => 'ro',
    format  => 'n',
    doc     => 'how loud should we yell',
    default => 1,
);

sub run {
    my ( $self ) = @_;
    uc ($self->message) . ( '!' ) x $self->loudness;
}

1;

