use parser;

class Serieborsen does Parser {

    method update ($db, $conf) {
        my $url = 'http://www.serieborsen.se/kortspel.html';
        say "Checking $url";
        my $html = download::site($url);
        #my $html = slurp("serieborsen.html");

        my @in_store = self.parse($html);
        my @new = self.filter_new($db, @in_store);
        for (@new) -> $x {
            say "NEW %$x<product> (%$x<price>:-)";
            my $json = to-json(%$x);
            $db.insert_event($json);
        }
    }

    method filter_new ($db, @parsed) {
        return @parsed.grep({ self.is_new($db, $_) });
    }

    method is_new ($db, $x) {
        # TODO generalize
        my $latest = $db.select_latest($x);
        return True unless $latest;

        $latest = from-json($latest);
        return %$latest<price> ne %$x<price>;
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

    method parse (Str $txt) {
        my @res;
        for $txt ~~ m:exhaustive/<StockList::TOP>/ -> $m {
            @res.push(self.parse_list($m));
        }

        return @res;
    }

    # Construct a list of parsed packs from parse tree
    method parse_list ($m) {
        my @res;

        # TODO better filtering
        # TODO generalize for other games
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

};

