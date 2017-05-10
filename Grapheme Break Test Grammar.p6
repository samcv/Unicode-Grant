#!/usr/bin/env perl6
my $location = "3rdparty/Unicode/9.0.0/ucd/auxiliary/GraphemeBreakTest.txt";
$location = "t/spec/$location".IO.e ?? "t/spec/$location" !! $location;
#die $location.IO.absolute;
my $folder = "";
use Test;
plan 2411;
constant $debug = False;

# Unicode Data files in 3rdparty/Unicode/ and the snippet of commented code below
# are under SPDX-License-Identifier: Unicode-DFS-2016
# See 3rdparty/Unicode/LICENSE for full text of license.
# From GraphemeBreakTest.txt Unicode 9.0

# Default Grapheme Break Test
#
# Format:
# <string> (# <comment>)? 
#  <string> contains hex Unicode code points, with 
#	÷ wherever there is a break opportunity, and 
#	× wherever there is not.
#  <comment> the format can change, but currently it shows:
#	- the sample character name
#	- (x) the Grapheme_Cluster_Break property value for the sample character
#	- [x] the rule that determines whether there is a break or not
constant %fudged-tests = {
    224 => ['ALL'],
    442 => [0],
    573 => ['ALL'],
    733 => ['ALL'],
    825 => ['ALL'],
    829 => [0],
    831 => ['ALL'],
    832 => ['ALL'],
    835 => ['ALL'],
    837 => ['ALL'],
    839 => ['ALL'],
};
sub MAIN (Str:D :$file? = $location, Str :$only?) {
    my @only = $only ?? $only.split([',', ' ']) !! Empty;
    die $file.IO.absolute unless $file.IO.f;
    my @fail;
    for $file.IO.lines -> $line {
        process-line $line, @fail, :@only;
    }
    my $bag = @fail.Bag;
    note "Grapheme_Cluster_Break test: Failed {$bag.elems} lines: ", $bag;
}

grammar GraphemeBreakTest {
    token TOP { [<.ws> [<break> | <nobreak>] <.ws>]+ % <hex> <comment> }
    token hex     { <:AHex>+ }
    token break   { '÷'      }
    token nobreak { '×'      }
    token comment { '#' .* $ }
}
class parser {
    has @!ord-array;
    method TOP ($/) {
        my @list =  $/.caps;
        my @stack;
        my @results;
        sub move-from-stack {
            if @stack {
                @results[@results.elems].append: @stack;
                @stack = [];
            }
        }
        for @list {
            if .key eq 'nobreak' {
                say 'nobreak' if $debug;
            }
            elsif .key eq 'break' {
                say 'break' if $debug;
                move-from-stack;
            }
            elsif .key eq 'hex' {
                @stack.push: :16(~.value);
            }
        }
        my $string =  @results».List.flat.chrs;
        move-from-stack;
        say @results.perl if $debug;
        make {
            string    => $string,
            ord-array => @results
        }
    }
}
sub process-line (Str:D $line, @fail, :@only) {
    state $line-no = 0;
    $line-no++;
    next if @only and $line-no ne @only.any;
    my Bool:D $fudge-b = %fudged-tests{$line-no}:exists ?? True !! False;
    return if $line.starts-with('#');
    my $list = GraphemeBreakTest.new.parse(
        $line,
        actions => parser.new
    ).made;
    if $fudge-b {
        # fudge is either set to ALL or set to 'C01234' woudl fudge character test
        # and graphemes 0 through 4. _01__4 would fudge character test, and graphemes 2 and 3
        if %fudged-tests{$line-no}.any eq 'ALL' {
            todo("line $line-no todo for {%fudged-tests{$line-no}.Str} tests", 1 + $list<ord-array>.elems);
            $fudge-b = False; # We already have todo'd don't attempt again
        }
    }
    if $fudge-b {
        # 6th index of fudge string <=> 5th string index (6th character)
        todo "$_ grapheme line $line-no todo" if %fudged-tests{$line-no}.any eq $_;
    }
    is-deeply $list<ord-array>.elems, $list<string>.chars, "Line $line-no: right num of chars | {$list<string>.uninames}" or @fail.push($line-no);
    for ^$list<ord-array>.elems {
        if $fudge-b {
            # 6th index of fudge string <=> 5th string index (6th character)
            if %fudged-tests{$line-no}.chars < $_ {
                #don't check
            }
            else {
                todo "$_ grapheme line $line-no todo" if %fudged-tests{$line-no}.any eq $_;
            }
        }
        is-deeply $list<string>.substr($_, 1).ords.flat, $list<ord-array>[$_].flat, "Line $line-no: grapheme $_ has correct codepoints" or @fail.push($line-no);
    }
}