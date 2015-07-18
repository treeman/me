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
#
sub register_plugins() {
    use plugins::test;
    my @plugins = (
        Test.new;
    );

    for (@plugins) -> $x {
        say $x.update;
    }
}

multi MAIN('test') {
    register_plugins;
}

role Plugin {

}

class A does Plugin {

}

class B is A {

}

multi MAIN('plugin_test') {
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
    # Would really want to load these dynamically!
    my @plugins = dir 'plugins';
    for (@plugins) -> $f {
        #say $f;
        #for $f.^methods() {
            #say $_.name;
        #}
        unless $f.basename() ~~ / (.+) \. (<-[.]>+) $ / {
            say "Failed to parse plugin: $f";
            next;
        }
        my $classname = $0.tc;
        say $classname;

        require $f;
        #require $f :OUR<ALL>;
        #my $c = $classname.new();
        #$c.update;
        #$f::update();
        #my $c = (require $f::Test).new;
    }
    #say test.Test;
    #update();
    #
    #require test:"plugins/test";
    #require ::("plugins/test");
    #my $c = test::Test.new;
    my $cn = "Test";
    my $c = Test.new;
    say $c.^name;

    say Plugin.HOW;
    say Plugin.^name();
    #say Plugin.^parents();
    say Plugin.^attributes;
    say B.^parents();
    say Plugin.^methods(:local);
    #say A.WHENCE;
    say A.^roles_to_compose;
}

