#!/usr/bin/env perl
use Test::More tests => 16;
use App::Cope qw[mark line colourise real_path];

# Needed for the real_path test
use File::Spec;
use Env::Path qw[:all];

sub test($&$$) {
  my ( $description, $sub, $in, $expected ) = @_;
  my $got = colourise( $sub, $in );
  $got =~ s/\033/\\E/g;
  is( $got, $expected, $description );
}

# Mark tests.

test 'mark with simple regex' => sub {
  mark qr{\w+} => qw[red];
},
  'bran flakes',
  '\\E[31mbran\\E[0m flakes';

test 'mark with more complicated regex' => sub {
  mark qr{^\|_\s.+} => 'magenta';
},
  '|_ HTML Title: Document Moved',
  '\\E[35m|_ HTML Title: Document Moved\\E[0m';

# Line tests

test 'line with one group' => sub {
  line qr{(\w+)} => 'red';
},
  'bran flakes',
  '\\E[31mbran\\E[0m \\E[31mflakes\\E[0m';

test 'line with two groups' => sub {
  line qr{^(\|_)\s(.+)} => 'magenta bold', 'magenta';
},
  '|_ HTML Title: Document Moved',
  '\\E[35;1m|_\\E[0m \\E[35mHTML Title: Document Moved\\E[0m';

test '^ only applied once' => sub {
  line qr{^(.)} => 'red';
},
  'hello',
  '\E[31mh\E[0mello';

sub configure_process {
  line qr{^checking .+\.{3} (.+)} => sub {
    my $r = shift;

    # two most common cases
    return 'green bold' if $r =~ m{(?:\(cached\)\s)?yes|none (?:needed|required)|done|ok};
    return 'red bold' if $r =~ m{no};

    # check for a found program or flag
    if ($r =~ m{^(?:(?:/usr)?/bin/)?(\w+)} and m{$1.*\.{3}}) {
      return 'green bold';
    }

    return 'yellow bold';
  };
}

test 'subroutine 1' => \&configure_process,
  'checking for sys/stat.h... yes',
  'checking for sys/stat.h... \\E[32;1myes\\E[0m';

test 'subroutine 2' => \&configure_process,
  'checking how to run the C preprocessor... gcc -E',
  'checking how to run the C preprocessor... \\E[33;1mgcc -E\\E[0m';

test 'subroutine 3' => \&configure_process,
  'checking for a sed that does not truncate output... /bin/sed',
  'checking for a sed that does not truncate output... \\E[32;1m/bin/sed\\E[0m';

test 'two lines matching the same text 1' => sub {
  line qr{(\d+)} => 'yellow';
  line qr{\d+\s+(\S+)} => 'blue';
},
  'go go 1234 shake boom!',
  'go go \\E[33m1234\\E[0m \\E[34mshake\\E[0m boom!';

test 'two lines matching the same text 2' => sub {
  line qr{\d+\s+(\S+)} => 'blue';
  line qr{(\d+)} => 'yellow';
},
  'go go 1234 shake boom!',
  'go go \\E[33m1234\\E[0m \\E[34mshake\\E[0m boom!';

test 'consecutive groups 1' => sub {
  mark qr{A} => 'on_red';
  mark qr{B} => 'red';
},
  'ABC',
  '\\E[41mA\\E[0;31mB\\E[0mC';

test 'consecutive groups 2' => sub {
  line qr{^(?:In file included from )?([^:]+:)([^:]+:)} => 'green bold', 'green';
},
  'fileschanged.c:95: error: too many arguments to function ‘perror’',
  '\\E[32;1mfileschanged.c:\\E[0;32m95:\\E[0m error: too many arguments to function ‘perror’';

test 'consecutive groups 3' => sub {
  mark qr{This is bold, } => 'green bold';
  mark qr{and this is, too!} => 'blue bold';
},
  'This is bold, and this is, too!',
  '\\E[32;1mThis is bold, \\E[34;1mand this is, too!\\E[0m';

test 'consecutive groups 4' => sub {
  mark qr{This is bold } => 'green bold';
  mark qr{but this should not be} => 'on_red';
},
  'This is bold but this should not be',
  '\\E[32;1mThis is bold \\E[0;41mbut this should not be\\E[0m';

# Test real_path with Nix-style wrapper
SKIP: {
  # Mock $0 to simulate a wrapped script path
  my $mock_script_name = ".ls-wrapped";
  my $mock_script_dir = File::Spec->catdir(File::Spec->tmpdir(), "test_cope_$$");
  my $mock_script_path = File::Spec->catfile($mock_script_dir, $mock_script_name);

  # Ensure App::Cope sees our mocked $0 by setting it early
  # However, $0 is global and App::Cope.pm caches its splitpath at load time.
  # This test will rely on the already loaded App::Cope.pm having $file as '.ls-wrapped'
  # if $0 was set to that value *before* App::Cope was loaded.
  # For an isolated test, one would typically use Test::MockModule or similar,
  # or ensure App::Cope is loaded *after* $0 is set.
  # Given the current structure, we proceed by ensuring App::Cope::real_path
  # correctly processes the $file variable derived from $0.

  # We need to ensure that App::Cope's own $file variable (derived from its $0)
  # is what we expect. This is tricky without deeper mocking or refactoring App::Cope.
  # For this test, we assume App::Cope.pm's $file will be '.ls-wrapped' if $0 is set accordingly.
  # This part of the setup is more conceptual for this specific test environment.
  # The core logic tested is how real_path uses its $file.

  my $original_whence;
  my $whence_called_with;

  BEGIN {
    $original_whence = \&Env::Path::PATH::Whence;
    no warnings 'redefine';
    *Env::Path::PATH::Whence = sub {
      my ($self, $program) = @_;
      $whence_called_with = $program;
      # Simulate $0 being found in the first path, and the real binary in the second
      if ($program eq "ls") { # This is the "unwrapped" name real_path should search for
        # $mock_script_path would be found by PATH->Whence($0)
        # real_path then calls PATH->Whence("ls")
        return ($mock_script_path, "/usr/bin/ls", "/bin/ls");
      }
      return ();
    };
  }

  # Set $App::Cope::file directly for testing real_path's internal logic
  # This is a more direct way to test real_path's manipulation of $file
  # without relying on the global $0's state at App::Cope load time.
  my $original_cope_file;
  {
    no warnings 'redefine';
    $original_cope_file = $App::Cope::file; # Save original
    $App::Cope::file = $mock_script_name; # Set to ".ls-wrapped"
  }

  # Also mock $0 itself for completeness, as real_path uses it for firstidx comparison
  my $original_script_0 = $0;
  $0 = $mock_script_path;

  my $expected_path = "/usr/bin/ls";
  my $found_path = App::Cope::real_path();

  is($found_path, $expected_path, "real_path finds correct path for .name-wrapped executable");
  is($whence_called_with, "ls", "PATH->Whence was called with the unwrapped name 'ls'");

  # Restore original Env::Path::PATH::Whence
  BEGIN {
    no warnings 'redefine';
    *Env::Path::PATH::Whence = $original_whence;
  }

  # Restore App::Cope::file and $0
  $App::Cope::file = $original_cope_file;
  $0 = $original_script_0;
}
