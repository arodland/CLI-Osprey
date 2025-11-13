package MyTest::Class::Basic::Yell;

use Moo;
use CLI::Osprey;

option excitement_level => (
    is => 'ro',
    format => 'i',
    doc => 'Level of excitement for yelling',
    default => 0,
);

# Example of underscored attribute name with short option that doesn't match first letter
# Tests the fix where option name becomes 'output-format' (hyphenated)
option output_format => (
    is => 'ro',
    format => 's',
    short => 'f',  # Note: 'f' not 'o' - doesn't match first letter
    doc => 'Output format (text, json, xml)',
    default => 'text',
);

# Another example with short option matching first letter
option repeat_count => (
    is => 'ro',
    format => 'i',
    short => 'r',  # Matches first letter of long option name
    doc => 'Number of times to repeat the yell',
    default => 1,
);

sub run {
    my ($self) = @_;
    my $message = uc $self->parent_command->message . "!" x $self->excitement_level;

    for (1 .. $self->repeat_count) {
        my $output;
        if ($self->output_format eq 'json') {
            $output = qq({"yell": "$message"});
        } elsif ($self->output_format eq 'xml') {
            $output = qq(<yell>$message</yell>);
        } else {
            $output = $message;
        }

        print "$output\n";
    }
}


1;
