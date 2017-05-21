use lib 't';
use Test::UniProp;
grammar BidiBrackets {
    rule TOP {
        <.ws>
        $<cp>=(<hex>)
        ';'
        $<Bidi_Paired_Bracket>=(<hex>)
        ';'
        <Bidi_Paired_Bracket_Type>
        '#'
        <uniname>
        <.ws>
    }
    token hex { <.ws> <:AHex>+ <.ws> }
    token Bidi_Paired_Bracket_Type { <allowed-chars> }
    token uniname { <allowed-chars> }
    token allowed-chars { <[\S\h]-[;#]>+ }

}
class BidiBrackets::Actions {
    sub radix_16 (Str() $string --> Int:D) {
        my Int $result = :16($string);
        if !$result.defined {
            use nqp;
            $result = nqp::radix_I(16, $string, 0, 0, 0)[0];
        }
        $result;
    }
    method TOP ($/) {
        make {
            codepoint => radix_16(~$<cp>),
            Bidi_Paired_Bracket => radix_16($<Bidi_Paired_Bracket>),
            Bidi_Paired_Bracket_Type => ~$<Bidi_Paired_Bracket_Type>,
            comment => ~$<uniname>
        }
    }

}
sub MAIN (Str:D $filename = "UNIDATA/BidiBrackets.txt") {
    for $filename.IO.lines {
        next if .starts-with('#') or $_ eq '';
        my $parse = BidiBrackets.new.parse($_,
            actions => BidiBrackets::Actions.new
            );
        $parse orelse next;
        my %hash = $parse.made;
        derive %hash;
        #is-prop-hash %hash;

    }

}
sub derive (%hash) {
    say %hash<codepoint>.uniprop('Bidi_Mirroring_Glyph') eq %hash<Bidi_Paired_Bracket>.chr;
    say so %hash<codepoint>.uniprop eq <Pe Pf Ps Pi>.any;
    #say "$_.base(16) $_.chr()" if .uniprop('Bidi_Mirroring_Glyph') and .uniprop eq <Pe Pf Ps Pi>.any
}
