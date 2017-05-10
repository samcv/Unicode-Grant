#!/usr/bin/env perl6
use v6;
my $location = "3rdparty/Unicode/9.0.0/ucd/auxiliary/GraphemeBreakTest.txt";
$location = "t/spec/$location".IO.e ?? "t/spec/$location" !! $location;
our $DEBUG;
use Test;
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
sub MAIN (Str:D :$file? = $location, Str :$only?, Bool:D :$debug = False) {
    my @only = $only ?? $only.split([',', ' ']) !! Empty;
    die "Can't find file at ", $file.IO.absolute unless $file.IO.f;
    note "Reading file ", $file.IO.absolute;
    my @fail;
    plan (@only.elems or 2411);
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
        note $/ if $DEBUG;
        sub move-from-stack {
            if @stack {
                @results[@results.elems].append: @stack;
                @stack = [];
            }
        }
        for @list {
            if .key eq 'nobreak' {
                say 'nobreak' if $DEBUG;
            }
            elsif .key eq 'break' {
                note 'break' if $DEBUG;
                move-from-stack;
            }
            elsif .key eq 'hex' {
                @stack.push: :16(~.value);
            }
        }
        my $string =  @results».List.flat.chrs;
        move-from-stack;
        note @results.perl if $DEBUG;
        make {
            string    => $string,
            ord-array => @results
        }
    }
}
sub process-line (Str:D $line, @fail, :@only!) {
    state $line-no = 0;
    $line-no++;
    return if @only and $line-no ne @only.any;
    return if $line.starts-with('#');
    my Bool:D $fudge-b = %fudged-tests{$line-no}:exists ?? True !! False;
    note 'LINE: [' ~ $line ~ ']' if $DEBUG;
    my $list = GraphemeBreakTest.new.parse(
        $line,
        actions => parser.new
    ).made;
    die "line $line-no undefined parse" if $list.defined.not;
    if $fudge-b {
        # fudge is either set to ALL or set to 'C01234' woudl fudge character test
        # and graphemes 0 through 4. _01__4 would fudge character test, and graphemes 2 and 3
        if %fudged-tests{$line-no}.any eq 'ALL' {
            todo("line $line-no todo for {%fudged-tests{$line-no}.Str} tests", 1 + $list<ord-array>.elems);
            $fudge-b = False; # We already have todo'd don't attempt again
        }
    }
    is-deeply $list<ord-array>.elems, $list<string>.chars, "Line $line-no: right num of chars | {$list<string>.uninames.perl}" or @fail.push($line-no);
    for ^$list<ord-array>.elems -> $elem {
        if $fudge-b {
            # 6th index of fudge string <=> 5th string index (6th character)
            if %fudged-tests{$line-no}.chars < $elem {
                #don't check
            }
            else {
                todo "$elem grapheme line $line-no todo" if %fudged-tests{$line-no}.any eq $elem;
            }
        }
        is-deeply $list<string>.substr($elem, 1).ords.flat, $list<ord-array>[$elem].flat, "Line $line-no: grapheme $elem has correct codepoints" or @fail.push($line-no);
    }
}