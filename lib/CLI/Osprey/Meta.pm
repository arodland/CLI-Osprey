package CLI::Osprey::Meta;

use Moo;

has 'parent' => (
    is => 'ro',
);

has 'command' => (
    is => 'ro',
);

has 'invoked_as' => (
    is       => 'ro',
    required => 1,
);

1;
