use parser;

class FFG does Parser {

    # TODO also check game of thrones!
    method update ($db, $conf) {
        my $url = 'https://www.fantasyflightgames.com/en/upcoming/';
        say "Checking $url";
        my $html = download::site($url);
        #my $html = slurp("ffg.html");

        my @upcoming = self.parse($html);
        my @new = self.filter_new($db, @upcoming);
        for (@new) -> $x {
            say "NEW %$x<product> (%$x<status>:-)";
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
        return %$latest<status> ne %$x<status>;
    }

    # Parse upcoming info.
    # TODO do something more intelligent with json value
    method parse (Str $txt) {
        my $json = self.parse_upcoming($txt);
        my @res;
        for (@$json) -> $x {
            if $x<collection_crumbs> ~~ /:i netrunner/ {
                # product: name
                # is_reprint: true/false
                # expected_by, expected_by_override
                # collection: Deluxe Expansion
                #             <cycle> Data Packs

                my $info = [
                    category => "netrunner",
                    product => $x<product>,
                    status => self.parse_status($x<name>),
                    location => "Fantasy Flight Games",
                    type => $x<collection>,
                ];
                @res.push($info);
            }
        }
        return @res;
    }

    grammar Upcoming {
        token TOP { <data_capture> }

        rule data_capture { upcoming_data \= (<-[ ; ]>+) \; };
    }

    method parse_upcoming (Str $txt) {
        if $txt ~~ / <Upcoming::TOP> / {
            return from-json (~$/<Upcoming::TOP><data_capture>[0]);
        }
        else {
            # TODO instead of dying, do some error checking!
            die "Could not parse upcoming data!";
        }
    }

    # XXX remove grammar, use a array/hash of allowed things?
    grammar Status {
        token TOP { ^ <status> $ }

        #ConceptStage InDev AwaitingReprint AtPrinter OnBoat Shipping Available
        rule status {
            Shipping Now
        | On the Boat
        | Awaiting Reprint
        | In Development
        | At the Printer
        | In Stores Now
        }
    }

    method parse_status(Str $txt) {
        my $m = Status.parse($txt);
        # TODO normalize?
        if $m { return ~$m<status> }
        else {
            warn "WARNING Could not parse FFG status for: '$txt'";
            return "";
        }
    }
};

