#!/usr/local/bin/perl6

use v6;
use DBIish;
use JSON::Tiny;
#use Grammar::Debugger;
use DateTime::Format;
use Term::ANSIColor;

use lib '.'; # Add current search directory for lib search

grammar Training {
    rule TOP {
        <entry>*
    }

    rule entry {
        ^^ <datetime>
        <category> [':' <description>]?
        [^^ <exercise>]*
        [^^ <comment>]?
    }

    rule comment {
        '#' <text>
    }

    rule text {
        \N+
    }

    rule datetime {
        <date> <time>?
    }

    rule date {
        \d**4 '-' \d**2 '-' \d**2
    }

    rule time {
        <minutes> | <hours>
    }

    rule minutes { \d+ min }

    rule hours { \d+ h }

    token category { <-[:\n]>+ }
    token description { \V+ }

    rule exercise {
        '*'
        <exercise_count>
        <exercise_name>
        <reps>
    }

    token exercise_count {
        \d+ x [\d+ | '?']
        ['s' | 'kg' | 'min' | 'h']?
    }

    token exercise_name { \w+ [\s \w+]* }

    rule reps {
        <rep>
        [',' <rep>]*
    }

    token rep { <real> | 'x' | 'v' }

    token real { \d+ ['.' \d+]? }
}

multi MAIN {
    my $txt = slurp("../scrap/training_file");
    say $txt;

    my $m = Training.parse($txt);
    say $m;

    #for $txt ~~ m:exhaustive/ <Training::TOP> / -> $m {
        #say ">>>>>>>>>>>>>>>>";
        #say $m;
        #say "<<<<<<<<<<<<<<<<";
        #exit;
    #}
}

