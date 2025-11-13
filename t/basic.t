#! perl

use Test::More;
use Capture::Tiny qw( capture );

use Test::Lib;
use MyTest::Class::Basic;

subtest 'command' => sub {

    subtest "default options" => sub {
        local @ARGV = ();
        my ( $stdout, $stderr, @result ) =
           capture { MyTest::Class::Basic->new_with_options->run };

        is ( $stdout, "Hello world!\n", "message sent to stdout" );
        is ( $stderr, '', "empty stderr" );

    };

    subtest "command line options" => sub {
        local @ARGV = ( '--message', 'Hello Cleveland!' );
        my ( $stdout, $stderr, @result ) =
           capture { MyTest::Class::Basic->new_with_options->run };

        is ( $stdout, "Hello Cleveland!\n", "message sent to stdout" );
        is ( $stderr, '', "empty stderr" );

    };

};

subtest 'subcommand' => sub {
    subtest 'yell class subcommand' => sub {
        require CLI::Osprey::Role;
        require MyTest::Class::Basic::Yell;
        my %options = MyTest::Class::Basic::Yell->_osprey_options();

        # Helper function: get getopt string for an option
        my $get_getopt_string = sub {
            my ($option_name) = @_;
            my %attrs = %{ $options{$option_name} };
            my $getopt = CLI::Osprey::Role::_osprey_option_to_getopt($option_name, %attrs);
            note("$option_name getopt string: $getopt");
            return $getopt;
        };

        # Helper function: run yell command and capture output
        my $run_yell_command = sub {
            my (@args) = @_;
            local @ARGV = ('yell', @args);
            local *CORE::exit = sub { };  # Prevent exit() from terminating test process
            my ($stdout, $stderr, @result) = capture { MyTest::Class::Basic->new_with_options->run };
            return ($stdout, $stderr);
        };

        # Helper function: run yell command and test output
        my $test_yell_command = sub {
            my ($args, $stdout_pattern, $description) = @_;
            my ($stdout, $stderr) = $run_yell_command->(@$args);
            like($stdout, $stdout_pattern, $description);
            is($stderr, '', "empty stderr");
            return ($stdout, $stderr);
        };

        subtest "default options" => sub {
            $test_yell_command->([], qr{^\QHELLO WORLD!\E\n$}, "message sent to stdout");
        };

        subtest "excitement_level option" => sub {
            subtest "internal: generates hyphenated getopt string" => sub {
                my $getopt = $get_getopt_string->('excitement_level');
                like($getopt, qr{\Qexcitement-level\E}, "generates hyphenated getopt string");
                unlike($getopt, qr{\Qexcitement_level\E}, "does not generate underscored getopt string");
            };

            subtest "functional: --excitement-level" => sub {
                $test_yell_command->([qw(--excitement-level 2)], qr{^\QHELLO WORLD!!!\E\n$},
                                 "excitement level adds exclamation marks");
            };
        };
    };

    subtest "inline subcommand" => sub {
        local @ARGV = qw ( whisper );
        local *CORE::exit = sub { };
        my ($stdout, $stderr) = capture { MyTest::Class::Basic->new_with_options->run };
        is ( $stdout, "hello world!\n", "message sent to stdout" );
        is ( $stderr, '', "empty stderr" );
    };

};

done_testing;
