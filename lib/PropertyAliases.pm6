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
#| Returns a hash whose keys are PropertyAliases and whose values are the short name
#| which is usable with GetPropertyValueLookupHash to look up different value aliases
sub GetPropertyAliasesRevLookupHash (Str $filename = 'UNIDATA/PropertyAliases.txt') is export {
    lookuphash-internal($filename)<rev-lookup>;
}
#| Returns a hash whose keys are PropertyAliases and whose values are the full names
sub GetPropertyAliasesLookupHash (Str $filename = 'UNIDATA/PropertyAliases.txt') is export {
    lookuphash-internal($filename)<lookup>;
}
sub GetPropertyAliasesList (Str $filename = 'UNIDATA/PropertyAliases.txt') is export {
    my %lookup-hash = GetPropertyAliasesLookupHash($filename);
    my @allprops;
    for %lookup-hash.keys {
        @allprops.push: $_;
        for  %lookup-hash{$_}.list -> $elem {
            @allprops.push: $elem;
        }
    }
    @allprops;
}
sub lookuphash-internal (Str $filename = 'UNIDATA/PropertyAliases.txt') {
    my $io = $filename.IO;
    my %rev-lookup-hash2;
    my %lookup-hash;
    for $io.lines {
        next if $_ eq '' or .starts-with('#');
        my $parse = PropertyAliases.new.parse($_,
            actions => PropertyAliases::Actions.new
        );
        my %hash = $parse.made // exit 1;
        for %hash<Property_Alias_Name> {
            %rev-lookup-hash2{$_} = %hash<Property_Name>;
            # Make sure to also map the short names to the short names themselves
            %rev-lookup-hash2{%hash<Property_Name>} = %hash<Property_Name>;
            %lookup-hash{%hash<Property_Name>} = $_;
            # Make sure to also map the full names to the full names themselves
            %lookup-hash{$_} = $_;
        }
    }
    %( rev-lookup => %rev-lookup-hash2, lookup => %lookup-hash);
}
