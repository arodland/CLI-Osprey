package Foo;
use Moo;
use CLI::Osprey
  doc => "The Moo Foo";

option foo => (
  is => 'ro',
  format => 's',
);

subcommand wibble => 'Foo::Wibble';

package main;
use Data::Dumper;
print Dumper({ Foo->_osprey_config });
print Dumper({ Foo->_osprey_options });
print Dumper({ Foo->_osprey_subcommands });

print Dumper([ Foo->parse_options ])
