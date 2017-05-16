unit module Test::UniProp;
use Test;
sub is-cp-prop ($thing, $codepoint, $property) is export {
    is $thing, $codepoint.uniprop($property);
}
sub is-prop-hash ($thing) is export {
    say $thing.perl;
    my $comment = $thing<comment> // $thing<uniname> // 'U+' ~ $thing<codepoint>.base(16);
    for $thing.keys {
        next if $_ eq any('comment', 'uniname', 'description', 'codepoint');
        is $thing<codepoint>.uniprop($_), $thing{$_}, "$_ | $comment";
    }
}
