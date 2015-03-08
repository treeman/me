# TODO error handling
# TODO cleanup
module ffg;

use DBIish;
use JSON::Tiny;
use db;

sub ffg_update_upcoming ($db, $txt) is export {
    my @upcoming = collect_new($db, parse_upcoming($txt));
    for (@upcoming) -> $obj {
        my $json_obj = to-json(%$obj);
        db_insert_event($db, $json_obj);
    }
}

sub collect_new ($db, @parsed) {
    return @parsed.grep({ is_new($db, $_) });
}

# TODO filter away somehow?
sub is_new ($db, $obj) {
    my $latest = select_latest($db, $obj);
    return True unless $latest;

    $latest = from-json($latest);
    return %$latest<status> ne %$obj<status>;
}

sub select_latest ($db, $obj) {
    my $sth = $db.prepare(q:to/STATEMENT/);
        SELECT * FROM events WHERE object->>'product' = ?
        ORDER BY created DESC LIMIT 1
        STATEMENT
    $sth.execute(%$obj<product>);

    return $sth.fetchrow_hashref()<object>;
}

# Parse upcoming info.
# TODO do something more intelligent with json value
sub parse_upcoming (Str $txt) {
    my $json = parse_upcoming_json ($txt);
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
                status => parse_status($x<name>),
                location => "Fantasy Flight Games",
                type => $x<collection>,
            ];
            @res.push($info);
        }
    }
    return @res;
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
    }
}

sub parse_status(Str $txt) {
    my $m = Status.parse($txt);
    # TODO normalize?
    if $m { return ~$m<status> }
    else {
        warn "WARNING Could not parse FFG status for: '$txt'";
        return "";
    }
}

# TODO make a test
#my $txt = "Shipping Now";
#my $status = parse_status($txt);
#say $status;