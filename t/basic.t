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

subtest "short" => sub {
    check_commandline(['-x', 'Shorts are comfy and easy to wear!'], qr/^Shorts are comfy and easy to wear!$/, qr/^$/);
};

subtest "prefix" => sub {
    check_commandline(['--mess', 'This is a mess.'], qr/This is a mess\.$/, qr/^$/);
};

subtest "short with two dashes", sub {
    TODO: {
        local $TODO = "We shouldn't accept a short option with two dashes, only a valid prefix of a long option";
        check_commandline(['--x', 'test'], qr//, qr/Unknown option: x/);
    }
};

done_testing;
