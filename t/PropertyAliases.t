my $line = 'ccc; 133; CCC133                     ; CCC133 # RESERVED';
use lib 't';
use Test::UniProp;
grammar PropertyAliases {
    rule TOP {
        <.ws>?
        <Property_Name> ';'
        <Property_Alias_Name>+ % ';'
        [
            [ <.ws>? ] |[ <.ws>? '#' .* ]
        ]
    }
    token hex { <:AHex>+ }
    token Property_Name { <.ws> <( <allowed-chars> )> <.ws> }
    token Property_Alias_Name { <.ws> <( <allowed-chars> )> <.ws> }
    token allowed-chars { <[\S]-[;]>+ }

}
class PropertyAliases::Actions {
    method TOP ($/) {
        make {
            Property_Name => ~$<Property_Name>,
            Property_Alias_Name =>  $<Property_Alias_Name>».Str
        }
    }

}
sub MAIN (Str:D $filename = 'UNIDATA/PropertyAliases.txt') {
    say GetPropertyAliasesLookupHash($filename);
}
sub GetPropertyAliasesLookupHash (Str $filename = 'UNIDATA/PropertyAliases.txt') is export {
    my $io = $filename.IO;
    chdir $io.dirname;
    use Test;
    my %lookup-hash;
    for $io.lines {
        next if $_ eq '' or .starts-with('#');
        my $parse = PropertyAliases.new.parse($_,
            actions => PropertyAliases::Actions.new
        );
        my %hash = $parse.made // exit 1;
        for %hash<Property_Alias_Name> {
            %lookup-hash{$_} = %hash<Property_Name>
        }
        #say %hash;
    }
    %lookup-hash;
}
