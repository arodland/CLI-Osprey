package OnDemand;

use Moo;
use CLI::Osprey;

subcommand foo => 'OnDemand::Foo';
subcommand bar => 'OnDemand::Bar';

sub run { }

1;
