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
    token nobreak {
        '÷'
    }
    token break {
        '×'
    }
    token comment {
        '#' .* $
    }
}
class parser {
    method TOP ($/) {
        make $/.caps
    }
}

my @list = GraphemeBreakTest.new.parse(
    '÷ 0378 × 0308 ÷ 0020 ÷	#  ÷ [0.2]'
    , actions => parser.new
).made;
#say @list;
my @stack;
my @results;
my @str;
sub move-from-stack {
    @results[@results.elems].append: @stack;
    @stack = [];
}
for @list {
    if .key eq 'nobreak' {
        say 'nobreak';
    }
    if .key eq 'break' {
        say 'break';
        move-from-stack;
    }
    if .key eq 'hex' {
        my Int:D $cp = :16(~.value);
        @str.push: $cp;
        @stack.push: $cp;
    }
}
move-from-stack;
say @results.perl;
my Str:D $string = @str.chrs;