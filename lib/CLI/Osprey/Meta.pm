package CLI::Osprey::Meta;

# ABSTRACT: Metadata subclass for CLI::Osprey use
# VERSION
# AUTHORITY

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
