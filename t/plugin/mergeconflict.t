use strict;
use warnings;

use autodie 'system';
use IPC::System::Simple (); # for autodie && prereqs

use File::chdir;
use Path::Class;

use Test::More;
use Test::Fatal;
use Test::Moose::More 0.004;
use Test::TempDir;

require 't/funcs.pm' unless eval { require funcs };

use Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts;

validate_class 'Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts' => (
    does => [
        'Dist::Zilla::Role::Git::Repo::More',
        'Dist::Zilla::Role::BeforeRelease',
    ],
);

sub _pm            { _ack('lib/DZT/Sample.pm' => undef, "message") }
sub _pm_conflicted { _ack('lib/DZT/Sample.pm' => undef, "another message") }

our_test(
    'Artificially-conflicted file',
    [ _pm_conflicted ],
    qr/Aborting release; found merge conflict markers:/,
);

done_testing;

sub our_tzil {
    my @additional = @_;

    #my ($tzil, $repo_root) = prep_for_testing(
    return prep_for_testing(
        repo_init => [
            sub { dir(qw{ lib DZT })->mkpath },
            _ack('lib/DZT/Sample.pm' => do { local $/; <DATA> }),
            @additional
        ],
        core_args   => { version => undef },
        plugin_list => [ qw(GatherDir Git::NextVersion Git::CheckFor::MergeConflicts FakeRelease) ],
    );
}

sub our_test {
    my ($name, $cmds, $test) = @_;

    my $test_sub
        = ref $test && ref $test eq 'CODE'
        ? $test
        : sub { like($_[0], $test, $_[1]) }
        ;

    my ($tzil, $repo_root) = our_tzil(
        _pm,
        (ref $cmds? (@$cmds) : $cmds),
        _ack('lib/DZT/Sample.pm' => undef, "a longer message... Lorem ipsum..."),
        _pm,
        _pm
    );

    my $thrown = exception { $tzil->release };
    diag_log($tzil, $test_sub->($thrown, $name));
    use Data::Dumper; warn Dumper $tzil;
}

__DATA__
package DZT::Sample;
<<<<<<< Updated upstream
use Something;
=======
use SomethingElse;
>>>>>>> master
1;
