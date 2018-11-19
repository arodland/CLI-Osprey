package MyTest::Class::Basic::Yell;

use Moo;
use CLI::Osprey;

sub run {
    my ($self) = @_;
    print uc $self->_meta->parent->message, "\n";
}


1;
