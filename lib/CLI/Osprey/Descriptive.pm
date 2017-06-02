package CLI::Osprey::Descriptive;

use strict;
use warnings;

# ABSTRACT: Getopt::Long::Descriptive subclass for CLI::Osprey use
# VERSION
# AUTHORITY

use Getopt::Long::Descriptive 0.100;
use CLI::Osprey::Descriptive::Usage;

our @ISA = ('Getopt::Long::Descriptive');

sub usage_class { 'CLI::Osprey::Descriptive::Usage' }

1;

__END__

=head1 DESCRIPTION

This class overrides L<Getopt::Long::Descriptive>'s C<usage_class> method to
L<Getopt::Long::Descriptive::Usage>, which provides customized help text. You
probably don't need to use it yourself.

=cut
