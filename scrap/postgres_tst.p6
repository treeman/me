use v6;
use DBIish;

#my $dbh = DBIish.connect("Pg", :database<example-db.sqlite3>, :RaiseError);
my $dbh = DBIish.connect("Pg", :user<postgres>, :RaiseError);

#my $sth = $dbh.do(q:to/STATEMENT/);
#    DROP TABLE nom
#    STATEMENT

my $sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE nom (
        name        varchar(4),
        description varchar(30),
        quantity    int,
        price       numeric(5,2)
    )
    STATEMENT

$sth = $dbh.do(q:to/STATEMENT/);
    INSERT INTO nom (name, description, quantity, price)
    VALUES ( 'BUBH', 'Hot beef burrito', 1, 4.95 )
    STATEMENT

$sth = $dbh.prepare(q:to/STATEMENT/);
    INSERT INTO nom (name, description, quantity, price)
    VALUES ( ?, ?, ?, ? )
    STATEMENT

$sth.execute('TAFM', 'Mild fish taco', 1, 4.85);
$sth.execute('BEOM', 'Medium size orange juice', 2, 1.20);

$sth = $dbh.prepare(q:to/STATEMENT/);
    SELECT name, description, quantity, price, quantity*price AS amount
    FROM nom
    STATEMENT

$sth.execute();

my $arrayref = $sth.fetchall_arrayref();
say $arrayref.elems; # 3

$sth.finish;

$dbh.disconnect;
