package Foo;
use Moo;
use CLI::Osprey
  doc => "The Moo Foo";

option opt => (
  is => 'ro',
  format => 's',
);

subcommand bar => 'Foo::Bar';
no Moo;

package Foo::Bar;
use Moo;
use CLI::Osprey;

option opt => (
  is => 'ro',
  format => 's',
);

package main;
use Data::Dumper;

#print Dumper({ Foo->_osprey_config });
#print Dumper({ Foo->_osprey_options });
#print Dumper({ Foo->_osprey_subcommands });

print Dumper(Foo->new_with_options);
