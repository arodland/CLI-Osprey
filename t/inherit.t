#! perl

use Test::More;
use Test::Fatal;

use Path::Tiny;

package CommonOptions {

    use Moo::Role;

    use CLI::Osprey;

    option inherit_no_default => (
        is      => 'ro',
        format  => 's',
        inherit => 1,
    );

    option inherit_default => (
        is      => 'ro',
        format  => 's',
        inherit => 1,
    );

    option not_inherited => (
        is     => 'ro',
        format => 's',
    );

}

package Cmd {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';


    has '+inherit_default' => ( is => 'ro', default => 'default value' );

    subcommand sc1 => 'SC1';
    subcommand sc1_1 => 'SC1_1';
    subcommand sc1_2 => 'SC1_2';
}

package SC1 {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';

    option falsely_inherited => (
        is      => 'ro',
        format  => 's',
        inherit => 1,
    );


    subcommand sc2   => 'SC2';
}


package SC2 {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';

    option falsely_inherited => (
        is      => 'ro',
        format  => 's',
        inherit => 1,
    );

}

package SC1_1 {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';

    subcommand sc2_1 => 'SC2_1';
}


package SC2_1 {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';

    option falsely_inherited => (
        is      => 'ro',
        format  => 's',
        inherit => 1,
    );
}

package SC1_2 {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';

    subcommand sc2_2 => 'SC2_2';
}


package SC2_2 {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';

    subcommand sc3_2 => 'SC3_2';

}

package SC3_2 {

    use Moo;

    use CLI::Osprey;

    with 'CommonOptions';

    option falsely_inherited => (
        is      => 'ro',
        format  => 's',
        inherit => 1,
    );
}


sub test_attrs {

    my ( $title, $ARGV, %expected ) = @_;

    local @ARGV = @$ARGV;
    my $cmd = Cmd->new_with_options;

    subtest $title => sub {

        while ( my ( $option, $value ) = each %expected ) {
            is( $cmd->$option, $value, "correct value for $option" );
        }

    };
}


subtest 'inherited' => sub {

    subtest 'command' => sub {

        test_attrs(
            'no values specified',
            [],
            inherit_no_default => undef,
            inherit_default    => 'default value',
            not_inherited      => undef
        );


        test_attrs(
            'values specified',
            [
                qw( --inherit_no_default=foo --inherit_default=goo --not_inherited=bar )
            ],
            inherit_no_default => 'foo',
            inherit_default    => 'goo',
            not_inherited      => 'bar',
        );

    };

    subtest 'first level sub-command' => sub {

        test_attrs(
            'no values specified',
            [qw( sc1 )],
            inherit_no_default => undef,
            inherit_default    => 'default value',
            not_inherited      => undef
        );

        test_attrs(
            'command values specified',
            [
                qw( --inherit_no_default=foo --inherit_default=goo --not_inherited=bar sc1 )
            ],
            inherit_no_default => 'foo',
            inherit_default    => 'goo',
            not_inherited      => undef,
        );


        test_attrs(
            'command & sub-command values specified',
            [
                qw( --inherit_no_default=foo --inherit_default=goo --not_inherited=bar
                  sc1
                  --inherit_no_default=foo1 --inherit_default=goo1 --not_inherited=bar1
                  )
            ],
            inherit_no_default => 'foo1',
            inherit_default    => 'goo1',
            not_inherited      => 'bar1',
        );

    };

    subtest 'second level sub-command' => sub {

        test_attrs(
            'no values specified',
            [qw( sc1 sc2 )],
            inherit_no_default => undef,
            inherit_default    => 'default value',
            not_inherited      => undef
        );

        test_attrs(
            'command values specified',
            [
                qw( --inherit_no_default=foo --inherit_default=goo --not_inherited=bar sc1 sc2 )
            ],
            inherit_no_default => 'foo',
            inherit_default    => 'goo',
            not_inherited      => undef,
        );


        test_attrs(
            'command & sub-command values specified',
            [
                qw( --inherit_no_default=foo --inherit_default=goo --not_inherited=bar
                  sc1
                  --inherit_no_default=foo1 --inherit_default=goo1 --not_inherited=bar1
                  sc2
                  )
            ],
            inherit_no_default => 'foo1',
            inherit_default    => 'goo1',
            not_inherited      => undef,
        );


        test_attrs(
            'command & sub-command & sub-sub-command values specified',
            [
                qw( --inherit_no_default=foo --inherit_default=goo --not_inherited=bar
                  sc1
                  --inherit_no_default=foo1 --inherit_default=goo1 --not_inherited=bar1
                  sc2
                  --inherit_no_default=foo2 --inherit_default=goo2 --not_inherited=bar2
                  )
            ],
            inherit_no_default => 'foo2',
            inherit_default    => 'goo2',
            not_inherited      => 'bar2',
        );

    };
};

subtest 'falsely inherited' => sub {

    subtest 'first level subcommand' => sub {

        local @ARGV = ( qw[ sc1 ] );
        my $cmd = Cmd->new_with_options;

        like(
            exception { $cmd->falsely_inherited },
            qr/'inherit.t' of 'sc1'/,
            'throws correctly'
        );
    };

    subtest 'second level subcommand' => sub {

        local @ARGV = ( qw[ sc1_1 sc2_1 ] );
        my $cmd = Cmd->new_with_options;

        like(
            exception { $cmd->falsely_inherited },
            qr{'inherit.t / sc1_1' of 'sc2_1'},
            'throws correctly'
        );
    };

    subtest 'third level subcommand' => sub {

        local @ARGV = ( qw[ sc1_2 sc2_2 sc3_2 ] );
        my $cmd = Cmd->new_with_options;

        like(
            exception { $cmd->falsely_inherited },
            qr{'inherit.t / sc1_2 / sc2_2' of 'sc3_2'},
            'throws correctly'
        );
    };

};

done_testing;
