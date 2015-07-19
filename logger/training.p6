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

class TrainingActions {
    method TOP($/) {
        #say "TOP = $/";
        #$/.make("asdf" ~ $/);
        #say $/; # This is the whole parse tree
        $/.make: $<entry>».made; # Make a parcel (immutable list) of the entries
    }

    method entry($/) {
        my %res = %(date => $<datetime>.made,
                    category => $<category>.made);

        my $description = $<description>.made;
        my $exercises = $<exercise>».made;
        my $comment = $<comment>.made;

        #say $exercises.elems;

        %res<description> = $description if $description;
        %res<exercises> = $exercises if $exercises;
        %res<comment> = $comment if $comment;

        $/.make(%res);
    }

    method datetime($/) {
        # TODO do something more clever here with duration?
        $/.make: ~$/.trim();
    }

    method category($/) { $/.make: ~$/ }
    method description($/) { $/.make: ~$/ }
    method comment($/) { $/.make: $<text>.made }
    method text($/) { $/.make: ~$/ }

    method exercise($/) {
        my %res = %(name => $<exercise_name>.made,
                    reps => $<reps>.made,
                    target => $<exercise_count>.made);
        $/.make(%res);
    }

    method exercise_name($/) { $/.make: ~$/ }
    # TODO this is not only repetitions, but something else as well. Weight sometimes!
    method reps($/) { $/.make: $<rep>».made }
    method rep($/) { $/.make: ~$/ }
    method exercise_count($/) { $/.make: ~$/ }
}

multi MAIN {
    my $txt = slurp("../scrap/training_file");
    #say $txt;

    my $actions = TrainingActions.new;
    my $m = Training.parse($txt, :$actions);
    #say $m;
    #say "Parsed training";
    #
    #say ">>>>>>>>>>>>>>>>";
    #say $m;
    #say "<<<<<<<<<<<<<<<<";
    #say "\n";
    #say ">>>>>>>>>>>>>>>>";
    my $res = $m.made;
    #say "<<<<<<<<<<<<<<<<";

    for (@$res) -> $x {
        say "* ", $x.perl;
        my %h = %$x;
    }

    #say to-json($res);

    #for $txt ~~ m:exhaustive/ <Training::TOP> / -> $m {
        #say ">>>>>>>>>>>>>>>>";
        #say $m;
        #say "<<<<<<<<<<<<<<<<";
        #exit;
    #}
}

