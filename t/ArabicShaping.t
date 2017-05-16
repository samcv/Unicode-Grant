my $line = ' 0600; ARABIC NUMBER SIGN; U; No_Joining_Group';
grammar ArabicShaping {
    rule TOP {
        <.ws>
        <hex> ';'
        <description> ';'
        <joining-type> ';'
        <joining-group>
        <.ws>
    }
    token hex { <.ws> <:AHex>+ <.ws> }
    token description { <.ws> <allowed-chars> <.ws> }
    token joining-group { <.ws> <allowed-chars> }
    token joining-type { <.ws> <allowed-chars> }
    token allowed-chars { <[\S\h]-[;]>+ }

}
class ArabicShaping::Actions {
    sub radix_16 (Str:D $string --> Int:D) {
        my Int $result = :16($string);
        if !$result.defined {
            use nqp;
            $result = nqp::radix_I(16, $string, 0, 0, 0)[0];
        }
    }
    method TOP ($/) {
        make {
            codepoint => :16(~$<hex>) // radix_16(~$<hex>),
            description => ~$<description>,
            joining-type => ~$<joining-type>,
            joining-group => ~$<joining-group>
        }
    }

}
sub MAIN (Str:D $filename = 'UNIDATA/ArabicShaping.txt') {
    my $io = $filename.IO;
    chdir $io.dirname;
    use Test;
    for $io.lines {
        my $parse = ArabicShaping.new.parse($_,
            actions => ArabicShaping::Actions.new
            );
        $parse orelse next;
        my %hash = $parse.made // exit;
        is %hash<codepoint>.uniprop('Joining_Group'), %hash<joining-group>, "Joining_Group %hash<description>";
        is %hash<codepoint>.uniprop('Joining_Type'), %hash<joining-type>, "Joining_Type %hash<description>";
    }
    done-testing;
}
