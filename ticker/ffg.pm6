module ffg;

# Parse upcoming info.
# TODO do something more intelligent with json value
sub parse_upcoming (Str $txt) is export {
    my $json = parse_upcoming_json ($txt);
    for (@$json) -> $x {
        if $x<collection_crumbs> ~~ /:i netrunner/ {
            # product: name
            # is_reprint: true/false
            # expected_by, expected_by_override
            # collection: Deluxe Expansion
            #             <cycle> Data Packs

            my %info = (
                category => "netrunner",
                product => $x<product>,
                status => parse_status($x<name>),
                location => "Fantasy Flight Games",
                type => $x<collection>,
            );

            # TODO store updates or something
            say %info;
        }

        parse_status($x<name>);
    }
}

sub parse_upcoming_json (Str $txt) {
    my rule data_capture { upcoming_data \= (<-[ ; ]>+) \; };
    if $txt ~~ / <data_capture> / {
        return from-json (~$/<data_capture>[0]);
    }
    else {
        # TODO instead of dying, do some error checking!
        die "Could not parse upcoming data!";
    }
}

# TODO remove grammar, use a array/hash of allowed things.
grammar Status {
    token TOP { ^ <status> $ }

    #ConceptStage InDev AwaitingReprint AtPrinter OnBoat Shipping Available
    rule status {
        Shipping Now | On the Boat | Awaiting Reprint | In Development | At the Printer
    }
}

sub parse_status(Str $txt) {
    my $m = Status.parse($txt);
    # TODO normalize?
    if $m { return ~$m<status> }
    else {
        warn "Could not parse FFG status for: '$txt'";
        return "";
    }
}

# TODO make a test
#my $txt = "Shipping Now";
#my $status = parse_status($txt);
#say $status;
