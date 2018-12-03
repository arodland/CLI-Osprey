#! perl

use Test::More;
use Capture::Tiny qw( capture );

use Test::Lib;
use MyTest::Class::Basic;

sub check_commandline {
    my ($args, $expected_stdout, $expected_stderr) = @_;
    local @ARGV = @$args;

    my ( $stdout, $stderr, @result ) =
        capture { MyTest::Class::Basic->new_with_options->run };

    like ( $stdout, $expected_stdout, "stdout" );
	like ( $stderr, $expected_stderr,  "stderr" );
}

subtest "default options" => sub {
    check_commandline([], qr/^Hello world!$/, qr/^$/);
};

subtest "command line options" => sub {
    check_commandline(['--message', 'Hello Cleveland!'], qr/^Hello Cleveland!$/, qr/^$/);
};

subtest "subcommand" => sub {
    subtest "default options" => sub {
        check_commandline(['yell'], qr/^HELLO WORLD!$/, qr/^$/);
    };
};

done_testing;
