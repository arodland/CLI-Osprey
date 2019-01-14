package MyCmd::Role::SubCommand;

use Moo::Role;

with 'MyCmd::Role::Config';

# this percolates up to the top level to retrieve the global message
# option
has '+parent_command' => (
    is      => 'ro',
    handles => ['message'],
);

1;

