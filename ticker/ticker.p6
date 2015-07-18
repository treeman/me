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

# Could possibly use LWP::Simple or something,
# but ssl doesn't work
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
    my $db = db_connect();

    # Print ticker stream by default
    my @events = db_event_stream($db);
    my @output;
    for (@events) -> $x {
        my ($json_obj, $seen, $created) = @$x;
        my $obj = from-json($json_obj);

        # TODO something smarter is needed...
        my $status = $obj<status>;
        $status = $obj<price> unless $status;

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
        db_mark_seen($db);
    }

    $db.disconnect;
}

multi MAIN('test') {
    #my $db = db_connect();

    #say color("red"), "Red!", color("reset");

    #db_delete_events($db);

    #ffg_update_upcoming($db, slurp("../data/ffg_upcoming.html"));
    #serieborsen_update_upcoming($db, slurp("../data/serieborsen.html"));

    #db_examine_events($db);
    #db_mark_seen($db);
    #db_examine_events($db);

    #$db.disconnect;
    #
    #say dir 'plugins';

    # Create a class/functino structure?
    my @plugins = dir 'plugins';
    for (@plugins) -> $f {
        require $f;
    }
}

