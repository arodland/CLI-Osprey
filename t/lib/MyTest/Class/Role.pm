package MyTest::Class::Role;

use Moo;
use CLI::Osprey;

with 'MyTest::Class::Role::Role';

sub run {
    my ($self) = @_;
    print $self->message, "\n";
}

1;
