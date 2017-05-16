my $line = ' 0600; ARABIC NUMBER SIGN; U; No_Joining_Group';
use lib 't';
use Test::UniProp;
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
        $result;
    }
    method TOP ($/) {
        make {
            codepoint => radix_16(~$<hex>),
            description => ~$<description>,
            Joining_Type => ~$<joining-type>,
            Joining_Group => ~$<joining-group>
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
        is-prop-hash %hash;
    }
    done-testing;
}
