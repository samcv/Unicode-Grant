#!/usr/bin/env perl6
constant $debug = False;
#÷ [0.2] SPACE (Other) ÷ [999.0] SPACE (Other) ÷ [0.3]

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
grammar GraphemeBreakTest {
    token TOP { [<.ws> [<break> | <nobreak>] <.ws>]+ % <hex> <comment> }
    token hex     { <:AHex>+ }
    token break   { '÷'      }
    token nobreak { '×'      }
    token comment { '#' .* $ }
}
class parser {
    has $!string;
    has @!ord-array;
    method TOP ($/) {
        my @list =  $/.caps;
        my @stack;
        my @results;
        my @str;
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
                my Int:D $cp = :16(~.value);
                @str.push: $cp;
                @stack.push: $cp;
            }
        }
        move-from-stack;
        say @results.perl if $debug;
        my Str:D $string = @str.chrs;
        make {
            string => $string,
            ord-array => @results
        }
    }
}
use Test;
sub process-line (Str:D $line, @fail) {
    state $line-no = 0;
    $line-no++;
    return if $line.starts-with('#');
    my $list = GraphemeBreakTest.new.parse(
        $line,
        actions => parser.new
    ).made;
    
    use Test;
    is-deeply $list<ord-array>.elems, $list<string>.chars, "Line $line-no: right num of chars #{$list<string>.uninames}" or @fail.push($line-no);
    for ^$list<ord-array>.elems {
        is-deeply $list<string>.substr($_, 1).ords.flat, $list<ord-array>[$_].flat, "Line $line-no: grapheme $_ has correct codepoints" or @fail.push($line-no);
    }
}
sub MAIN (Str:D $file) {
    die unless $file.IO.f;
    my @fail;
    for $file.IO.lines -> $line {
        process-line $line, @fail;
    }
    done-testing;
    my $bag = @fail.Bag;
    note "Grapheme_Cluster_Break test: Failed {$bag.elems} lines: ", $bag;
}
