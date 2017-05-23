my $line = 'ccc; 133; CCC133                     ; CCC133 # RESERVED';
use lib 't';
use lib 'lib';
use PropertyAliases;
use Test::UniProp;
sub MAIN (Str:D $filename = 'UNIDATA/PropertyAliases.txt', Bool:D :$test) {
    if $test {
        test-it;
    }
    else {
         GetPropertyAliasesLookupHash($filename);
    }
}
sub test-it {
    my %lookup-hash = GetPropertyAliasesLookupHash;
    use nqp;
    require Test <&is &done-testing>;
    for %lookup-hash.keys -> $propname {
        is nqp::unipropcode($propname),
            nqp::unipropcode(%lookup-hash{$propname}),
            "$propname %lookup-hash{$propname}";
    }
    done-testing;
}
