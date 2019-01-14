#! perl

use Test::More;

use Path::Tiny;

use constant ROOT_PATH => path( qw[ eg config_file ] )->stringify;
use constant CFG_FILE  => path( ROOT_PATH, 'sayit.ini' )->stringify;

use lib path( ROOT_PATH, 'lib' )->stringify;

use MyCmd;

subtest 'sayit' => sub {

    subtest 'no config, no options' => sub {
        local @ARGV = ();
        is( MyCmd->new_with_options->run, 'Hello World' );
    };

    subtest 'no config,options' => sub {
        local @ARGV = ( '--message', 'No Config, Options' );
        is( MyCmd->new_with_options->run, 'No Config, Options' );
    };

    subtest 'config, no options' => sub {
        local @ARGV = ( '--config', CFG_FILE );
        is( MyCmd->new_with_options->run, 'from config' );
    };

    subtest 'config, options' => sub {
        local @ARGV = ( '--config', CFG_FILE, '--message', 'Config, Options' );
        is( MyCmd->new_with_options->run, 'Config, Options' );
    };

};

subtest 'sayit yell' => sub {

    subtest 'sayit' => sub {

        subtest 'no config, no options' => sub {
            local @ARGV = ( 'yell' );
            is( MyCmd->new_with_options->run, 'HELLO WORLD!' );
        };

        subtest 'no config, options' => sub {
            local @ARGV = ( '--message', 'No Config, Options', 'yell' );
            is( MyCmd->new_with_options->run, 'NO CONFIG, OPTIONS!' );
        };

        subtest 'config, no options' => sub {
            local @ARGV = ( '--config', CFG_FILE, 'yell' );
            is( MyCmd->new_with_options->run, 'FROM CONFIG!!' );
        };

        subtest 'config, options' => sub {
            local @ARGV
              = ( '--config', CFG_FILE, '--message', 'Config, Options',
                'yell' );
            is( MyCmd->new_with_options->run, 'CONFIG, OPTIONS!!' );
        };

    };

    subtest 'yell' => sub {

        subtest 'no config, no options' => sub {
            local @ARGV = ( 'yell' );
            is( MyCmd->new_with_options->run, 'HELLO WORLD!' );
        };

        subtest 'no config, options' => sub {
            local @ARGV = ( 'yell', '--loud', 4 );
            is( MyCmd->new_with_options->run, 'HELLO WORLD!!!!' );
        };

    };

};

subtest 'sayit yell quietly' => sub {

    subtest 'sayit' => sub {

        subtest 'no config, no options' => sub {
            local @ARGV = ( 'yell', 'quietly' );
            is( MyCmd->new_with_options->run, 'Sh: Hello World' );
        };

        subtest 'no config, options' => sub {
            local @ARGV = ( '--message', 'No Config, Options', 'yell', 'quietly' );
            is( MyCmd->new_with_options->run, 'Sh: No Config, Options' );
        };

        subtest 'config, no options' => sub {
            local @ARGV = ( '--config', CFG_FILE, 'yell', 'quietly' );
            is( MyCmd->new_with_options->run, 'Shhhhh: from config' );
        };

        subtest 'config, options' => sub {
            local @ARGV
              = ( '--config', CFG_FILE, '--message', 'Config, Options',
                'yell', 'quietly' );
            is( MyCmd->new_with_options->run, 'Shhhhh: Config, Options' );
        };

    };

    subtest 'yell quietly' => sub {

        subtest 'no config, no options' => sub {
            local @ARGV = ( 'yell', 'quietly' );
            is( MyCmd->new_with_options->run, 'Sh: Hello World' );
        };

        subtest 'no config, options' => sub {
            local @ARGV = ( 'yell', 'quietly', '--quiet', 4 );
            is( MyCmd->new_with_options->run, 'Shhhhh: Hello World' );
        };

    };

};

done_testing;
