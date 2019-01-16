#! perl

use Test::More;
use Test::Fatal;

{
  package App;

  use Moo;
  use CLI::Osprey;

  option bool => ( is => 'ro', );

  option negatable_bool => (
    is        => 'ro',
    option    => 'nbool',
    default   => !!1,
    negatable => 1,
  );

  option repeatable_bool => (
    is         => 'ro',
    option     => 'rbool',
    repeatable => 1,
  );

  option string => (
    is     => 'ro',
    format => 's'
  );

  option repeatable_string => (
    is         => 'ro',
    option     => 'rstring',
    format     => 's',
    repeatable => 1,
  );

  option repeatable_kv_string => (
    is         => 'ro',
    option     => 'kvstring',
    format     => 's',
    repeatable => 1,
    keyvalue   => 1,
  );

  option integer => (
    is     => 'ro',
    format => 'i'
  );

  option float => (
    is     => 'ro',
    format => 'f',
  );

}

subtest bool => sub {

  {
    local @ARGV = qw( --bool );
    is( !!App->new_with_options->bool, !!1, 'standard bool' );
  }

  {
    local @ARGV = qw( --no-nbool );
    is( !!App->new_with_options->negatable_bool, !!0, 'negatable bool' );
  }

  {
    local @ARGV = qw( --rbool --rbool --rbool );
    is( App->new_with_options->repeatable_bool, 3, 'repeatable bool' );
  }
};

subtest string => sub {

  {
    local @ARGV = qw( --string=foo );
    is( App->new_with_options->string, 'foo', 'standard string' );
  }

  subtest 'repeatable string as array' => sub {

    {
      local @ARGV = ();
      is( App->new_with_options->repeatable_string,
	undef, 'repeatable string, 0 entries' );
    }

    {
      local @ARGV = qw( --rstring=foo );
      is_deeply( App->new_with_options->repeatable_string,
	['foo'], 'repeatable string, 1 entries' );
    }

    {
      local @ARGV = qw( --rstring=foo --rstring=bar );
      is_deeply( App->new_with_options->repeatable_string,
	[qw( foo bar )], 'repeatable string, 2 entries' );
    }
  };

  subtest 'repeatable string as key value' => sub {

    {
      local @ARGV = ();
      is( App->new_with_options->repeatable_kv_string,
	undef, 'key value string, 0 entries' );
    }

    {
      local @ARGV = qw( --kvstring foo=bar );
      is_deeply(
	App->new_with_options->repeatable_kv_string,
	{ foo => 'bar' },
	'key value string, 1 entries'
      );
    }

    {
      local @ARGV = qw( --kvstring foo=bar --kvstring bar=baz );
      is_deeply(
	App->new_with_options->repeatable_kv_string,
	{ foo => 'bar', bar => 'baz' },
	'repeatable string, 2 entries'
      );
    }
  };

};

subtest integer => sub {

  {
    local @ARGV = qw( --integer=1 );
    is( App->new_with_options->integer, 1, 'integer' );
  }

  {
    local $SIG{__WARN__} = sub { die @_ };
    local @ARGV = qw( --integer=foo );
    like( exception { App->new_with_options->integer },
      qr/invalid/, 'bad value', );
  }

};

done_testing;
