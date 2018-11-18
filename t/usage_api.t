#! perl

use Test2::V0;

use CLI::Osprey::Descriptive::Usage;

can_ok(
    'CLI::Osprey::Descriptive::Usage',
       'new',
       'text',
       'leader_text',
       'warn',
       'die',

       # option_text() is part of the Getopt::Long::Descriptive::Usage API, but
       # seems only to be used within ::Usage, so maybe it doesn't need
       # to be implemented?
       # 'option_text',
);


done_testing;
