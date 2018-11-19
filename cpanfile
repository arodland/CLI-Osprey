requires 'Moo';
requires 'Moo::Role';
requires 'Getopt::Long::Descriptive';
requires 'Module::Runtime';
requires 'Path::Tiny';

on 'test' => sub {
   requires 'Test2::V0';
   requires 'Test::Lib';
   requires 'Capture::Tiny';
};