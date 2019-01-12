#! perl

use Test::More;
use Capture::Tiny qw( capture );

use Test::Lib;
use MyTest::Class::Role;

use constant CLASS => MyTest::Class::Role;

subtest "default options" => sub {
    local @ARGV = ();
    my ( $stdout, $stderr, @result )
      = capture { CLASS->new_with_options->run };

    is( $stdout, "Hello world!\n", "message sent to stdout" );
    is( $stderr, '', "empty stderr" );

};

subtest "command line options" => sub {
    local @ARGV = ( '--message', 'Hello Cleveland!' );
    my ( $stdout, $stderr, @result )
      = capture { CLASS->new_with_options->run };

    is( $stdout, "Hello Cleveland!\n", "message sent to stdout" );
    is( $stderr, '', "empty stderr" );

};

done_testing;
