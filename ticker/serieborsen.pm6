module serieborsen;

use DBIish;
use JSON::Tiny;
use db;

sub serieborsen_update_upcoming ($db, $txt) is export {
    my @upcoming = collect_new($db, parse_upcoming($txt));
    for (@upcoming) -> $obj {
        say "NEW %$obj<product> (%$obj<status>)";
        my $json_obj = to-json(%$obj);
        db_insert_event($db, $json_obj);
    }
}

sub collect_new ($db, @parsed) {
    return @parsed.grep({ is_new($db, $_) });
}

# TODO filter away somehow?
sub is_new ($db, $obj) {
    my $latest = select_latest($db, $obj);
    return True unless $latest;

    $latest = from-json($latest);
    return %$latest<status> ne %$obj<status>;
}

sub select_latest ($db, $obj) {
    my $sth = $db.prepare(q:to/STATEMENT/);
        SELECT * FROM events WHERE object->>'product' = ?
        ORDER BY created DESC LIMIT 1
        STATEMENT
    $sth.execute(%$obj<product>);

    return $sth.fetchrow_hashref()<object>;
}

grammar StockList {
    rule TOP {
        <preface>
        <content>
        { say ">>> DONE (content)<<<\n", $/<content><table><content_row> }
    }

    rule preface {
        '<' td <attribute>* '>'
        <title>
        <tag('p')>*
        '</' td '>'
    }

    rule content {
        '<' td <attribute>* '>'
        <table>
        '</' td '>'
    }

    rule table {
        '<' table <attribute>* '>'
        '<' tbody '>'
        <content_row>*
        '</' tbody '>'
        '</' table '>'
    }

    rule content_row {
        '<' tr <attribute>* '>'
        (<td>+)
        '</' tr '>'
    }

    rule td {
        '<' td <attribute>* '>'
        (<xml>)
        '</' td '>'
    }

    token xml { <text> [ <tag> <text> ]* }

    multi rule tag {
        '<' (\w+) <attribute>* '>'
        <xml>
        '</' $0 '>'
    }
    rule attribute {
        \w+ '="' <-["<>]>* \"
    }
    token text { <-[<>]>* }

    multi rule tag ($x) {
        '<' $x <attribute>* '>'
        <xml>
        '</' $x '>'
    }

    rule title { 
        '<' p '>'
        '<span' class \= '"rubrik"' <attribute>* '>'
        'ANDROID:' NETRUNNER
        '</span>'
        '</' p '>'
    }
}

# Parse upcoming info.
# TODO do something more intelligent with json value
sub parse_upcoming (Str $txt) {
    #while $txt ~~ / <StockList::TOP> / {
        #say $/;
    #}
    #say "DONE";
    for $txt ~~ m:exhaustive/<StockList::TOP>/ -> $m {
        #say "NEW";
        #say ~$m;
        say $m.from;
        #if ~$m ~~ / NETRUNNER / {
            #say ~$/;
            #}
    }
    #if $txt ~~ / <StockList::TOP> / {
        #say $/;
        ##return from-json (~$/<Upcoming::TOP><data_capture>[0]);
    #}
    #else {
        ## TODO instead of dying, do some error checking!
        #die "Could not parse upcoming data!";
    #}

    my @res;
    #for (@$json) -> $x {
        #say $x;
        ##if $x<collection_crumbs> ~~ /:i netrunner/ {

            ##my $info = [
                ##category => "netrunner",
                ##product => $x<product>,
                ##status => "In Stock / Out of Stock",
                ##location => "Seriebörsen",
                ###type => "Remov??",
            ##];
            ##@res.push($info);
        ##}
    #}
    return @res;
}


