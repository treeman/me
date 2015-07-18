module serieborsen;

use DBIish;
use JSON::Tiny;
use db;

sub serieborsen_update_upcoming ($db, $txt) is export {
    my @stock = collect_new($db, parse_stock($txt));
    for (@stock) -> $obj {
        say "NEW %$obj<product> (%$obj<price>:-)";
        my $json_obj = to-json(%$obj);
        $db.insert_event($json_obj);
    }
}

sub collect_new ($db, @parsed) {
    return @parsed.grep({ is_new($db, $_) });
}

# TODO filter away somehow?
sub is_new ($db, $obj) {
    my $latest = $db.select_latest($obj);
    return True unless $latest;

    $latest = from-json($latest);
    return %$latest<price> ne %$obj<price>;
}

# Just a stupid grammar...
# Works but it's stupid and inefficient.
# Might redo it if it breaks, heh!
grammar StockList {
    rule TOP {
        <preface>
        #{ say ~$/<preface><title> }
        <content>
    }

    rule preface {
        '<' td <attribute>* '>'
        <title>
        <tag('p')>*
        '</' td '>'
    }

    rule content {
        '<' td <attribute>* '>'
        <table>
        '</' td '>'
    }

    rule table {
        <tag('p')>*
        '<' table <attribute>* '>'
        <content_row>*
        '</' table '>'
    }

    rule content_row {
        '<' tr <attribute>* '>'
        (<td>+)
        '</' tr '>'
    }

    rule td {
        '<' td <attribute>* '>'
        (<xml>)
        '</' td '>'
    }

    token xml { <text> [ <tag> <text> ]* }

    multi rule tag {
        '<' (\w+) <attribute>* '>'
        <xml>
        '</' $0 '>'
    }
    rule attribute {
        \w+ '="' <-["<>]>* \"
    }
    token text { <-[<>]>* }

    multi rule tag ($x) {
        '<' $x <attribute>* '>'
        <xml>
        '</' $x '>'
    }

    rule title {
        # TODO somewhere here Yu-Gi-Oh! and others break
        '<' p <attribute>* '>' 
        '<' (\w+) class \= '"rubrik"' <attribute>* '>'
        (<xml>) # Actual title
        '</' $0 '>'
        '</' p '>'
    }
}

# Parse upcoming info.
sub parse_stock (Str $txt) {
    my @res;
    for $txt ~~ m:exhaustive/<StockList::TOP>/ -> $m {
        @res.push(construct_content($m));
    }

    return @res;
}

# TODO test these
grammar Item {
    rule TOP {
        ^
        <name>
        <id>?
    }

    token name {
        (<-[<>()]>+)
    }

    rule id {
        '('
        (<-[)]>+)
        ')'
    }
}

# Construct a list of parsed packs from parse tree
sub construct_content ($m) {
    my @res;

    # TODO better filtering
    my $title = ~$m<StockList::TOP><preface><title>[1];
    next unless $title ~~ m/:i netrunner/;

    # XXX This is hilariously stupid... :D
    # TODO fix this, use Grammar.subparse (but that needs a start location!)
    # Anyways might want to prettify!!
    my $rows = $m<StockList::TOP><content><table><content_row>;
    for (@$rows) -> $x {
        for (@$x) -> $y {
            my $product = ~$y<td>[0][0];
            $product ~~ s:g/ '&nbsp;' //;

            my $price = ~$y<td>[1][0];
            $price ~~ s:g/ '&nbsp;' //;

            if $price ~~ m/:i slut / {
                #say "Skipping: $product because of: $price";
                next;
            }

            if Item.subparse($product) {
                my $product = ~$/<name>.trim();
                my $info = [
                    category => "netrunner",
                    product => $product,
                    price => $price,
                    location => "Seriebörsen",
                    # XXX data pack/deluxe or something?
                    #type => $x<collection>,
                ];

                @res.push($info);
            }
            #else {
                #say "FAIL    '$name'";
            #}
        }
    }

    return @res;
}

# How to check existing methods.
#for StockList.^methods() {
    #say $_.name;
#}

