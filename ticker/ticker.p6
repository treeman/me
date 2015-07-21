#!/usr/local/bin/perl6
#
# TODO need to escape/unescape html across the board?!?
# https://perl6advent.wordpress.com/2010/12/21/day-21-transliteration-and-beyond/
# Could not find a module...!?

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
    use parsers::naver;
    use parsers::mangadoom;

    my @parsers = (
        Serieborsen.new,
        FFG.new,
        Kubera.new,
        Naver.new,
        Mangadoom.new,
    );

    return @parsers;
}

sub get_conf() {
    return from-json(slurp("ticker.json"));
}

multi MAIN('update') {
    say "Updating...";

    my $conf = get_conf();
    my $db = db::DB.new;
    my @parsers = list_parsers;

    for (@parsers) -> $x {
        $x.update($db, $conf);
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
    my $conf = get_conf();
    my $db = db::DB.new;

    use parsers::naver;
    my $c = Naver.new;
    $c.update($db, $conf);
}

