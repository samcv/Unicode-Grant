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
    token break-nobreak {
        <nobreak> | <break>
    }
    token hex {
        <:AHex>+
    }
    token break {
        '÷'
    }
    token nobreak {
        '×'
    }
    token comment {
        '#' .* $
    }
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
            if .key eq 'break' {
                say 'break' if $debug;
                move-from-stack;
            }
            if .key eq 'hex' {
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
sub process-line (Str:D $line) {
    return if $line.starts-with('#');
    my $list = GraphemeBreakTest.new.parse(
        #'÷ 0378 × 0308 ÷ 0020 ÷	#  ÷ [0.2]'
        $line
        #'÷ AC00 × 200D ÷ #'
        #'÷ 0020 ÷ 0020 ÷	#  ÷ [0.2] SP'
        , actions => parser.new
    ).made;
    
    use Test;
    is-deeply $list<ord-array>.elems, $list<string>.chars, "Right num of chars";
    for ^$list<ord-array>.elems {
        is-deeply $list<string>.substr($_, 1).ords.flat, $list<ord-array>[$_].flat, "Grapheme $_";
    }
}
sub MAIN (Str:D $file) {
    die unless $file.IO.f;
    for $file.IO.lines -> $line {
        process-line $line;
    }
    done-testing;
}
