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
sub MAIN (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt', Bool:D :$test = False) {
    if $test {
        test-it;
    }
    else {
        #say GetPropertyValueLookupHash($filename).gist;
        require 'PropertyAliases.t' <&GetPropertyAliasesLookupHash &GetPropertyAliasesList>;
        my %lookup-hash = GetPropertyAliasesLookupHash;
        my @allprops = GetPropertyAliasesList;
        my %hash = GetPropertyValueLookupHash($filename);
        my @list;
        my %has-hash;
        for %hash.keys -> $key {
            for %hash{$key}.list {
                for .list {
                    @list.push: $_;
                    if %has-hash{$_}:!exists {
                        %has-hash{$_}.push($key);
                    }
                    elsif %has-hash{$_}.none eq $key {
                        %has-hash{$_}.push($key);
                    }
                }
            }
        }
        my @strs;
        for @list -> $elem {
            if @allprops.any eq $elem {
                my $msg = ' '.uniprop($elem) ~~ Bool ?? " is a boolean property" !! '';
                say '«« ', $elem, ' Conflict with property name ', %has-hash{$elem}, ' ', $msg;
            }

        }
        my @order = <General_Category Script Grapheme_Cluster_Break Canonical_Combining_Class Numeric_Type>;
        sub abcdefg ($note, $next-list, $next-key?) {
            for %has-hash.grep({.value.elems > 1}).sort(-*.value.elems) -> $elem {
                my $str = $elem.key ~ ' => ["';
                my @list;
                for $elem.value.list {
                    @list.push: %lookup-hash{$_};
                }
                next if $next-key and $next-key($elem.key);
                next if $next-list(@list, $elem);
                $str ~= @list.join(“", "”) ~ '"],';
                @strs.push($str);
            }
            say $note;
            @strs.join("\n").say;
        }
        my $a = sub (@list) { @list.any eq <Script Block>.all }
        my $b = sub (@list) { @list.any ne <Script Block>.all }
        my $order-sub = sub (@list, $elem?) {
            if @list.any eq @order.any {
                for @order {
                    my $grep = @list.grep($_).Str;
                    if $grep {
                        say '» ', $elem.key, ' => ', $grep;
                        last;
                    }
                }
                return True;
            }
        }
        my $next-key = sub ($key) {
            return $key eq <True False T F Yes No Y N>.any;
        }
        abcdefg('So far unresolved:', $order-sub, $next-key);
        #abcdefg("# All except <True False T F Yes No Y N> and Script/Block overlaps", $a, $next-key);
        #abcdefg("# Only Script/Block overlap", $b, $next-key);
        exit;
    }
}
#| Returns a hash whose keys are PropertyValues and whose values are list's of list's.
#| AHex => [[N No F False] [Y Yes T True]],
sub GetPropertyValueLookupHash (Str:D $filename = 'UNIDATA/PropertyValueAliases.txt') is export {
    my $io = $filename.IO;
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
sub test-it {
    use lib 't';
    require 'PropertyAliases.t' <&GetPropertyAliasesRevLookupHash>;
    my %lookup-hash = GetPropertyAliasesRevLookupHash;
    my %values-hash = GetPropertyValueLookupHash;
    use nqp;
    require Test <&is &ok &done-testing &is-deeply>;
    for %values-hash.keys -> $propname {
        my int $propcode = nqp::unipropcode($propname);
        for ^%values-hash{$propname}.elems -> $elem {
            my $pvalue-array = %values-hash{$propname}[$elem];
            my @results;
            for %values-hash{$propname}[$elem].list -> $value {
                @results.push: nqp::unipvalcode($propcode, $value);
            }
            is-deeply @results.all, @results.all, "$propname: All (" ~ %values-hash{$propname}[$elem].list ~ ") are the same unipvalcode (@results.join(', '))" ;


        }
    }
    done-testing;
}
