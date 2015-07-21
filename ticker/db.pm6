module db;

use DBIish;

class DB {
    has $!db_instance;

    # Lazy initialization of db connection.
    method db {
        unless $!db_instance {
            say "connecting to db";
            # TODO config file? :)
            $!db_instance = DBIish.connect("Pg", :user<postgres>, :database<me>, :RaiseError);
        }
        return $!db_instance;
    }

    method select_events {
        my $sth = self.db.prepare("SELECT * FROM events");
        $sth.execute();
        return @($sth.fetchall_arrayref());
    }

    method event_stream {
        my $sth = self.db.prepare(q:to/STATEMENT/);
            SELECT object, seen,
                to_char(created, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS created
            FROM events
            WHERE seen = False
            ORDER BY created
            STATEMENT
        $sth.execute();

        return @($sth.fetchall_arrayref());
    }

    method mark_seen {
        return self.db.do(q:to/STATEMENT/);
            UPDATE events
            SET seen = True
            STATEMENT
    }

    method delete_events {
        return self.db.do(q:to/STATEMENT/);
            DELETE FROM events
            STATEMENT
    }

    method examine_events {
        say "\n>>>>> events <<<<<";
        for (self.select_events()) -> $x {
            #say "X: ", @$x;
            my ($json_txt, $seen, $created) = @$x;
            my $json_obj = from-json($json_txt);
            say $json_obj;
            say $seen;
            say $created;
        }
    }

    method insert_event ($json_obj) {
        my $sth = self.db.prepare(q:to/STATEMENT/);
            INSERT INTO events
            VALUES (?)
            STATEMENT
        return $sth.execute($json_obj);
    }

    method select ($sql, *@rest) {
        my $sth = self.db.prepare($sql);
        $sth.execute(@rest);

        return @($sth.fetchall_arrayref());
    }

    method select_one ($sql, *@rest) {
        my $sth = self.db.prepare($sql);
        $sth.execute(@rest);

        return $sth.fetchrow_hashref();
    }

    # TODO only for netrunner??
    method select_latest ($obj) {
        my $sth = self.db.prepare(q:to/STATEMENT/);
            SELECT * FROM events
            WHERE object->>'product' = ?
            AND object->>'location' = ?
            ORDER BY created DESC LIMIT 1
            STATEMENT
        $sth.execute(%$obj<product>, %$obj<location>);

        return $sth.fetchrow_hashref()<object>;
    }

    method disconnect {
        say "disconnecting from db";
        $!db_instance.disconnect;
        $!db_instance = Any;
    }
};

