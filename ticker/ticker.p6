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

my $db = DBIish.connect("Pg", :user<postgres>, :database<me>, :RaiseError);
my $sth;

#update_upcoming(slurp("../data/ffg_upcoming.html"), $db);
my $obj = ["category" => "netrunner",
           "product" => "Creation and Control",
           "status" => "Shipping Now",
           "location" => "Fantasy Flight Games",
           "type" => "Deluxe Expansions",
          ];
my $json_obj = to-json (%$obj);
#say $json_obj;

#$db.do(q:to/STATEMENT/);
    #DELETE FROM events
    #STATEMENT

#$sth = $db.do(qq:to/STATEMENT/);
    #INSERT INTO events
    #VALUES ('$json_obj')
    #STATEMENT

my $name = %$obj<product>;
# 1. Select latest update
$sth = $db.prepare(qq:to/STATEMENT/);
    SELECT * FROM events WHERE object->>'product' = 'Creation and Control'
    ORDER BY created DESC LIMIT 1
    STATEMENT
$sth.execute();

my $ref = $sth.fetchrow_hashref();
say $ref;
my $res = $ref<object>;
if $res {
    say from-json ($res);
}

# 2. If current status != old status, we have a new event
# 3. Later check filtering. For netrunner, check if we already have the pack!

$sth = $db.prepare("SELECT * FROM events");
$sth.execute();

#say $sth.fetchall_arrayref();

say "";
say ">>>>> events <<<<<";
for @($sth.fetchall_arrayref()) -> $x {
    #say "X: ", @$x;
    my ($json_txt, $seen, $created) = @$x;
    my $json_obj = from-json($json_txt);
    say $json_obj;
    say $seen;
    say $created;
}

$sth.finish;

$db.disconnect;

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
