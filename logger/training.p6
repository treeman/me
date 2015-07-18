#!/usr/local/bin/perl6

use v6;
use DBIish;
use JSON::Tiny;
#use Grammar::Debugger;
use DateTime::Format;
use Term::ANSIColor;

use lib '.'; # Add current search directory for lib search

grammar Entry {
    rule TOP {
        ^^ <datetime>
        ^^ <category> #[':' <description>]?
        ^^ <exercise>
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

    token exercise {
        <exercise_count>
        <exercise_name>
        <reps>
    }

    token exercise_count {
        \d+ x [\d+ | '?']
    }

    token exercise_name { \D+ }

    rule reps {
        <rep>
        [',' <rep>]*
    }

    token rep { \d+ | 'x' }
}

multi MAIN {
    my $txt = slurp("../scrap/training_file");
    say $txt;

    for $txt ~~ m:exhaustive/ <Entry::TOP> / -> $m {
        say $m;
        exit;
    }
}

