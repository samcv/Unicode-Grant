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
#| Returns a hash whose keys are PropertyValues and whose values are list's of list's.
#| AHex => [[N No F False] [Y Yes T True]],
#| The first value in the array is the shortened property value, and the second
#| one is the long form one. The ones after that point are additional aliases
multi sub GetPropertyValueLookupHash (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt') is export {
    state %lookup-hash;
    if !%lookup-hash {
        my $io = $filename.IO;
        for $io.lines {
            next if $_ eq '' or .starts-with('#');
            my $parse = PropertyValueAliases.new.parse($_,
                actions => PropertyValueAliases::Actions.new
            );
            $parse // exit 1;
            my %hash = $parse.made // exit 1;
            %lookup-hash{%hash<Property_Name>}.push: %hash<Alias_Name>;
        }
    }
    %lookup-hash;
}
multi sub GetPropertyValueLookupHash (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt', :long-property-names) is export {
    my %lookup-hash = GetPropertyValueLookupHash($filename);
    my %long-pname-lookup-hash;
    #use thing;

}
