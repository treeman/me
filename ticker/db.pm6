module db;

use DBIish;

sub db_connect is export {
    return DBIish.connect("Pg", :user<postgres>, :database<me>, :RaiseError);
}

sub db_insert_event ($db, $json_obj) is export {
    # Insert event
    my $sth = $db.prepare(q:to/STATEMENT/);
        INSERT INTO events
        VALUES (?)
        STATEMENT
    return $sth.execute($json_obj);
}

sub db_examine_events ($db) is export {
    say "\n>>>>> events <<<<<";
    for (db_select_events($db)) -> $x {
        #say "X: ", @$x;
        my ($json_txt, $seen, $created) = @$x;
        my $json_obj = from-json($json_txt);
        say $json_obj;
        say $seen;
        say $created;
    }
}

sub db_select_events ($db) is export {
    my $sth = $db.prepare("SELECT * FROM events");
    $sth.execute();

    return @($sth.fetchall_arrayref());
}

sub db_event_stream ($db) is export {
    my $sth = $db.prepare(q:to/STATEMENT/);
        SELECT * FROM events
        WHERE seen = False
        ORDER BY created
        STATEMENT
    $sth.execute();

    return @($sth.fetchall_arrayref());
}

sub db_mark_seen ($db) is export {
    return $db.do(q:to/STATEMENT/);
        UPDATE events
        SET seen = True
        STATEMENT
}

sub db_delete_events ($db) is export {
    return $db.do(q:to/STATEMENT/);
        DELETE FROM events
        STATEMENT
}
