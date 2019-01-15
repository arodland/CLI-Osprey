package MyTest::Class::Config::Yell::Quietly;
use Moo;
use CLI::Osprey;

with 'MyTest::Class::Config::Role::SubCommand';

option quiet => (
    is      => 'ro',
    format  => 'n',
    doc     => 'how quiet should we yell',
    default => 0,
);

sub run {
    my ( $self ) = @_;
    "Sh" . ( 'h' ) x $self->quiet . ': ' . $self->message;
}

1;

