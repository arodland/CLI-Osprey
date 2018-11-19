package MyCmd::Yell;
use Moo;
use CLI::Osprey;

with 'MyCmd::SubCommandRole';

subcommand quietly => __PACKAGE__ . '::Quietly';

has '+parent_command' => (
    is      => 'ro',
    handles => ['message'],
);

option loudness => (
    is      => 'ro',
    format  => 'n',
    doc     => 'how loud should we yell',
    default => 1,
);

sub run {
    my ( $self ) = @_;
    print uc $self->message, ( '!' ) x $self->loudness, "\n";
}

1;

