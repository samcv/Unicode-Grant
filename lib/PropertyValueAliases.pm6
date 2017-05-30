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
#| Note. Does not return a positional for integer properties, instead returns
#| a string which contains the Unicode datafile reason/null value for that property
sub GetPropertyValueLookupHash (
Str:D $filename = 'UNIDATA/PropertyValueAliases.txt',
Bool:D :$use-short-pnames = True
) is export {
    state %lookup-hash;
    use PropertyAliases;
    if !%lookup-hash {
        my $io = $filename.IO;
        for $io.lines {
            next if $_ eq '';
            if .contains('@missing') {
                .match: /:s ^ '# @missing: 0000..10FFFF;' $<pname>=(<[\S]-[;]>+) ';' $<reason>=(<[\S]-[;]>.*) /;
                die "Failed to parse line: '$_'" unless $<pname>;
                %lookup-hash<long>{ GetPropertyAliasesLookupHash{~$<pname>} } = ~$<reason>;
                %lookup-hash<short>{GetPropertyAliasesRevLookupHash{~$<pname>} } = ~$<reason>;
                next;
            }
            next if .starts-with('#');
            my $parse = PropertyValueAliases.new.parse($_,
                actions => PropertyValueAliases::Actions.new
            );
            $parse // die $_;
            my %hash = $parse.made // die "'$_'";
            die %hash.perl if %hash<missing>:exists;
            #for %hash<Alias_Name>.list {
                %lookup-hash<short>{%hash<Property_Name>}.push: %hash<Alias_Name>;
                %lookup-hash<long>{ GetPropertyAliasesLookupHash{%hash<Property_Name>} }.push: %hash<Alias_Name>;
            #}
        }
    }
    $use-short-pnames ?? %lookup-hash<short> !! %lookup-hash<long>;
}
sub GetPropertyValue-to-long-value-LookupHash (
Str:D $filename = 'UNIDATA/PropertyValueAliases.txt',
:$use-short-pvalues = False,
:$use-short-pnames = False
) is export {
    state %new-hash;
    state %settings;
    use PropertyAliases;
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
            #say $propname, %hash{$propname};
            # Skip integer propertys
            next if %hash{$propname} !~~ Positional;
            for %hash{$propname}.list -> $pvalue-array {
                die "Missed a value? ", $pvalue-array.perl if $pvalue-array.elems < 2;
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
