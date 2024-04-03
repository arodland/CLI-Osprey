package MyTest::Class::Role::Role;

use Moo::Role;
use CLI::Osprey;

option 'message' => (
    is => 'ro',
    format => 's',
    doc => 'The message to display',
    default => 'Hello world!',
);

1;
