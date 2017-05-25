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
#| Returns a hash whose values arrays of all the property names which are equivalent
sub GetPropertyAliases (Str $filename = 'UNIDATA/PropertyAliases.txt') is export {
    state %state;
    if !%state {
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
                my Str $short-name = %hash<Property_Name>.Str;
                my Str $long-name  = $_.Str;
                %rev-lookup-hash2{$long-name}.push: $short-name;
                %rev-lookup-hash2{$long-name}.push: $long-name;
                %lookup-hash{$short-name}.push: $long-name;
                %lookup-hash{$short-name}.push: $short-name;
            }
        }
        %state = %( long => %rev-lookup-hash2, short => %lookup-hash);
    }
    %state;
}
sub lookuphash-internal (Str $filename = 'UNIDATA/PropertyAliases.txt') {
    state %state;
    if !%state {
        my $io = $filename.IO;
        my Str %rev-lookup-hash2;
        my Str %lookup-hash;
        for $io.lines {
            next if $_ eq '' or .starts-with('#');
            my $parse = PropertyAliases.new.parse($_,
                actions => PropertyAliases::Actions.new
            );
            my %hash = $parse.made // exit 1;
            for %hash<Property_Alias_Name> {
                my Str $short-name = %hash<Property_Name>.Str;
                my Str $long-name  = $_.Str;
                %rev-lookup-hash2{$long-name} = $short-name;
                # Make sure to also map the short names to the short names themselves
                %rev-lookup-hash2{$short-name} = $short-name;
                %lookup-hash{$short-name} = $long-name;
                # Make sure to also map the full names to the full names themselves
                %lookup-hash{$long-name} = $long-name;
            }
        }
        %state = %( rev-lookup => %rev-lookup-hash2, lookup => %lookup-hash);
    }
    %state;
}
