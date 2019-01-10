package MyCmd::Yell::Quietly;
use Moo;
use CLI::Osprey;

with 'MyCmd::Role::SubCommand';

option quiet => (
    is      => 'ro',
    format  => 'n',
    doc     => 'how quiet should we yell',
    default => 0,
);

sub run {
    my ( $self ) = @_;
    print  "Sh", ( 'h' ) x $self->quiet, ': ', $self->message, "\n";
}

1;

