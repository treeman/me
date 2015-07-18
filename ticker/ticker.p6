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

# Could possibly use LWP::Simple or something,
# but ssl doesn't work...?
sub fetch_site (Str $url) {
    my $html = qq:x/curl "$url"/;
    return $html;
}

sub get_encoding (Str $file) {
    my $encoding = qq:x/file -i $file/;
    if $encoding ~~ / charset \= (\S+) / {
        return ~$0;
    }
    else {
        warn "WARNING could not get encoding for `$file`";
        return "";
    }
}

sub fetch_non_utf8_site (Str $url) {
    # TODO how to automatically generate?
    my $tmpfile = "$*TMPDIR/tmp_download.html";

    my $exit_code = run 'curl', '-o', $tmpfile, $url;
    if $exit_code == 0 {

        my $encoding = get_encoding($tmpfile);
        my $html = qq:x/iconv -f $encoding -t UTF-8 $tmpfile/;

        unlink($tmpfile);

        return $html;
    }
    else {
        warn "WARNING curl failed to download `$url`";
        return "";
    }
}

multi MAIN('update') {
    say "Updating...";

    my $db = db_connect();

    {
        my $html = fetch_site('https://www.fantasyflightgames.com/en/upcoming/');
        ffg_update_upcoming($db, $html);
    }

    {
        # TODO they changed their site!
        my $html = fetch_non_utf8_site('http://www.serieborsen.se/kortspel.html');
        #my $html = slurp("../data/serieborsen2.html");
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
    my $db = db::DB.new;
    #my @events = $db.select_events;
    #my @events2 = $db.select_events;
    #
    #$db.examine_events;

    my @plugins = list_plugins;

    for (@plugins) -> $x {
        $x.update;
    }
}

