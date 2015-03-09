#!/usr/local/bin/perl6

use v6;
use DBIish;
use JSON::Tiny;
#use Grammar::Debugger;

use lib '.'; # Add current search directory for lib search
use ffg;
use db;
use serieborsen;

# XXX Must have https requests, but
# $ panda install IO::Socket::SSL
# ==> IO::Socket::SSL depends on OpenSSL
# ==> Fetching OpenSSL
# ==> Building OpenSSL
# Compiling lib/OpenSSL/Bio.pm6 to mbc
# ===SORRY!===
# Type 'long' is not declared
# at lib/OpenSSL/Bio.pm6:41
# ------>     has long⏏ $.num_read;
# Malformed has
# at lib/OpenSSL/Bio.pm6:41
# ------>     has ⏏long $.num_read;
# build stage failed for OpenSSL: Failed building lib/OpenSSL/Bio.pm6
#
# So for now, use the almighty curl
#my $url = 'https://fantasyflightgames.com/en/upcoming/';
#my $html = qq:x/curl "$url"/;
#say $html.WHAT;
#say $html;

multi MAIN('update') {
    say "Updating...";

    my $db = db_connect();

    #ffg_update_upcoming($db, slurp("../data/ffg_upcoming.html"));
    serieborsen_update_upcoming($db, slurp("../data/serieborsen.html"));
    #db_examine_events($db);

    $db.disconnect;
}

multi MAIN(Bool :$mark) {
    my $db = db_connect();

    # Print ticker stream by default
    my @events = db_event_stream($db);
    for (@events) -> $x {
        my ($json_obj, $seen, $created) = @$x;
        my $obj = from-json($json_obj);

        # TODO different printing for different events
        say "$obj<product>   ($obj<status> @ $obj<location>)";
    }

    # Mark everything as seen
    if $mark {
        db_mark_seen($db);
    }

    $db.disconnect;
}

multi MAIN('test') {
    my $db = db_connect();

    db_delete_events($db);
    ffg_update_upcoming($db, slurp("../data/ffg_upcoming.html"));

    db_examine_events($db);
    db_mark_seen($db);
    db_examine_events($db);

    $db.disconnect;
}

