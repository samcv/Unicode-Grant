#!/usr/bin/env perl6
sub MAIN (Str :$filename, Bool:D :$dry-run = False) {
    my $OWD = $*CWD;
    my Bool:D $has-pulled = False;
    die "You need to clone git@github.com:samcv/Unicode-Grant.wiki.git into ./wiki" unless "wiki".IO.d;
    my @files = $filename // dir.grep({.extension eq 'pod6' and !.starts-with('.')});
    for @files -> $filename {
        chdir $OWD;
        my $file-io = $filename.IO;
        run 'pod-render.pl6', '--md', $file-io;
        my $file-md = ($file-io.Str.subst(/'.'.*$/, '') ~ '.md');
        $file-md.IO.move('wiki' ~ '/' ~ $file-md);
        chdir 'wiki';
        if $has-pulled.not {
            qqx{git pull};
            $has-pulled = True;
        }
        qqx{git add '$file-md'} unless $dry-run;
    }

    qx{git commit -m 'update'} unless $dry-run;
    qx{git push} unless $dry-run;
}
