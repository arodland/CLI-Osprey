requires 'Moo';
requires 'Moo::Role';
requires 'Getopt::Long::Descriptive';
requires 'Module::Runtime';
requires 'Path::Tiny';

on 'test' => sub {
   requires 'Test::More';
   requires 'Test::Lib';
   requires 'Capture::Tiny';
};
