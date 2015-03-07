use v6;
use DBIish;
use JSON::Tiny;
#use Grammar::Debugger;

use lib '.'; # Add current search directory for lib search
use ffg;

sub db_things {
    my $dbh = DBIish.connect("Pg", :user<postgres>, :database<me>, :RaiseError);

    my $obj = to-json {
        category => "netrunner",
        datapack => "the valley",
        status => "available",
        location => "speljätten",
    };

    #say $obj;

    #my $sth = $dbh.do(qq:to/STATEMENT/);
    #    INSERT INTO events
    #    VALUES ('netrunner_thevalley_speljatten', '$obj')
    #    STATEMENT

    my $sth = $dbh.prepare("SELECT * FROM events");
    $sth.execute();

    #say $sth.fetchall_arrayref();

    for @($sth.fetchall_arrayref()) -> $x {
        my ($id, $json_txt) = @$x;
        my $json_obj = from-json($json_txt);
        say $id;
        say $json_obj;
    }

    $sth.finish;

    $dbh.disconnect;
}

my $file = "ffg_upcoming.html";
my $content = slurp($file);

parse_upcoming($content);
