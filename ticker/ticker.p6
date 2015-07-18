#!/usr/local/bin/perl6

use v6;
use DBIish;
use JSON::Tiny;
#use Grammar::Debugger;
use DateTime::Format;
use Term::ANSIColor;

use lib '.'; # Add current search directory for lib search
use db;
use jagged;
use download;

sub list_parsers() {
    # Would like to find this list dynamically on runtime.
    # But I couldn't figure out how to load the classes.
    use parsers::serieborsen;
    use parsers::ffg;
    use parsers::kubera;

    my @parsers = (
        Serieborsen.new,
        FFG.new,
        Kubera.new,
    );

    return @parsers;
}


multi MAIN('update') {
    say "Updating...";

    my $db = db::DB.new;
    my @parsers = list_parsers;

    for (@parsers) -> $x {
        $x.update($db);
    }
}

multi MAIN(Bool :$mark) {
    my $db = db::DB.new;

    # Print ticker stream by default
    my @events = $db.event_stream;
    my @output;
    for (@events) -> $x {
        my ($json_obj, $seen, $created) = @$x;
        my $obj = from-json($json_obj);

        # TODO refactor into printer plugins or whatever...!
        if $obj<category> eq "netrunner" {
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
        else {
            my @row;
            @row.push("$obj<manga>");
            if $obj<season> {
                @row.push("$obj<season>x$obj<chapter> ($obj<location>)");
            }
            else {
                @row.push("$obj<chapter> ($obj<location>)");
            }
            my $dt = DateTime.new($created);
            @row.push(strftime("%e %b, %H:%M", $dt));

            @output.push(\@row);
        }
    }

    .say for balanced_width_columns(@output, 2);

    # Mark everything as seen
    if $mark {
        $db.mark_seen;
    }
}

multi MAIN('test') {
    my $db = db::DB.new;

    use parsers::kubera;
    my $c = Kubera.new;
    $c.update($db);
}

