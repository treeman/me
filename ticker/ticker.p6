#!/usr/local/bin/perl6

use v6;
use DBIish;
use JSON::Tiny;
#use Grammar::Debugger;
use DateTime::Format;
use Term::ANSIColor;

use lib '.'; # Add current search directory for lib search
use ffg;
use db;
use serieborsen;
use jagged;
use download;

multi MAIN('update') {
    say "Updating...";

    my $db = db::DB.new;

    {
        my $html = download::site('https://www.fantasyflightgames.com/en/upcoming/');
        ffg_update_upcoming($db, $html);
    }

    {
        # TODO they changed their site!
        my $html = download::site('http://www.serieborsen.se/kortspel.html');
        serieborsen_update_upcoming($db, $html);
    }

    $db.disconnect;
}

multi MAIN(Bool :$mark) {
    my $db = db::DB.new;

    # Print ticker stream by default
    my @events = $db.event_stream;
    my @output;
    for (@events) -> $x {
        my ($json_obj, $seen, $created) = @$x;
        my $obj = from-json($json_obj);

        # TODO something smarter is needed...
        my $status = $obj<status>;
        $status = $obj<price> unless $status;
        $status = "?" unless $status;

        my @row;
        @row.push("$obj<product>");
        @row.push("$obj<location> ($status)");
        my $dt = DateTime.new($created);
        @row.push(strftime("%e %b, %H:%M", $dt));

        @output.push(\@row);
    }

    .say for balanced_width_columns(@output, 2);

    # Mark everything as seen
    if $mark {
        $db.mark_seen;
    }
}

sub list_plugins() {
    # Would like to find this list dynamically on runtime.
    # But I couldn't figure out how to load the classes.
    use plugins::test;
    my @plugins = (
        Test.new;
    );

    return @plugins;
}

multi MAIN('test') {
    #my $db = db::DB.new;
    #my @plugins = list_plugins;

    #for (@plugins) -> $x {
        #$x.update;
    #}
    #my $html = fetch_non_utf8_site('https://www.fantasyflightgames.com/en/upcoming/');
    #say $html;

    #my $html = fetch_non_utf8_site('http://www.serieborsen.se/kortspel.html');
    #say $html;
}

