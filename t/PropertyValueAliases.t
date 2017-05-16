my $line = 'ccc; 133; CCC133                     ; CCC133 # RESERVED';
use lib 't';
use Test::UniProp;
grammar PropertyValueAliases {
    rule TOP {
        <.ws>?
        <Property_Name> ';'
        <Alias_Name>+ % ';'
        [
            [ <.ws>? ] |[ <.ws>? '#' .* ]
        ]
    }
    token hex { <:AHex>+ }
    token Property_Name { <.ws> <( <allowed-chars> )> <.ws> }
    token Alias_Name { <.ws> <( <allowed-chars> )> <.ws> }
    token allowed-chars { <[\S]-[;]>+ }

}
class PropertyValueAliases::Actions {
    method TOP ($/) {
        make {
            Property_Name => ~$<Property_Name>,
            Alias_Name =>  $<Alias_Name>».Str
        }
    }

}
sub MAIN (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt') {
    GetPropertyValueLookupHash($filename);
}
#| Returns a hash whose keys are PropertyValues and whose values are list's of list's.
#| AHex => [[N No F False] [Y Yes T True]],
sub GetPropertyValueLookupHash (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt') is export {
    my $io = $filename.IO;
    chdir $io.dirname;
    my %lookup-hash;
    for $io.lines {
        next if $_ eq '' or .starts-with('#');
        my $parse = PropertyValueAliases.new.parse($_,
            actions => PropertyValueAliases::Actions.new
        );
        my %hash = $parse.made // exit 1;
        %lookup-hash{%hash<Property_Name>}.push: %hash<Alias_Name>;
    }
    %lookup-hash;
}
