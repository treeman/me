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

parse_upcoming(slurp("../data/ffg_upcoming.html"));

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
