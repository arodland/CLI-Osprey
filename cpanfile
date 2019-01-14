requires 'Moo';
requires 'Moo::Role';
requires 'Getopt::Long::Descriptive';
requires 'Module::Runtime';
requires 'Path::Tiny';

on 'test' => sub {
   requires 'Test::More' => 1;
   requires 'Test::Lib';
   requires 'Test::Fatal';
   requires 'Capture::Tiny';
};
