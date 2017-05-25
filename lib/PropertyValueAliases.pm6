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
sub GetPropertyValueLookupHash (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt') is export {
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
sub GetPropertyValue-to-long-value-LookupHash (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt', :$use-short-pvalues = False, :$use-short-pnames = False) is export {
    state %new-hash;
    state %settings;
    #use lib 'Unicode-Grant/lib';
    use PropertyAliases;
    #sub settings-right ($var? ) {
    #    so( (%settings<use-short-pvalues> == $use-short-pvalues) && (%settings<use-short-pnames> eq $use-short-pnames) )
    #}
    sub get-pname ($pname) {
        if !$use-short-pnames {
            return GetPropertyAliasesLookupHash{$pname};
        }
        else {
            return $pname;
        }
    }
    if !%new-hash || !%settings || (%settings<use-short-pvalues> != $use-short-pvalues) || (%settings<use-short-pnames> != $use-short-pnames) {
        my %hash = GetPropertyValueLookupHash;
        die unless %hash;
        for %hash.keys -> $propname {
            for %hash{$propname}.list -> $pvalue-array {
                my $short = $pvalue-array[0];
                my $long  = $pvalue-array[1];
                my @extra = $pvalue-array[2..*];

                my $go-to   = $use-short-pvalues ?? $short !! $long;
                my $go-from = $use-short-pvalues ?? $long  !! $short;

                my $desig-propname = get-pname($propname);
                for ($go-from, @extra).flat -> $going-from {
                    %new-hash{$desig-propname}{$going-from} = $go-to;
                }
                %new-hash{$desig-propname}{$go-to} = $go-to;
            }

        }
        %settings<use-short-pvalues> = $use-short-pvalues;
        %settings<use-short-pnames>  = $use-short-pnames;
    }
    %new-hash;
}
