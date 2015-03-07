use v6;
use DBIish;
use JSON::Tiny;

#say from-json('{ "a": 42 }').perl;
#say to-json { a => [1, 2, 'b'] };

my $dbh = DBIish.connect("Pg", :user<postgres>, :database<json_test>, :RaiseError);

#my $sth = $dbh.do(q:to/STATEMENT/);
#    DROP TABLE nom
#    STATEMENT

#my $sth = $dbh.do(q:to/STATEMENT/);
    #INSERT INTO books
    #VALUES (1,
      #'{ "name": "Book the First", "author": { "first_name": "Bob", "last_name": "White" } }')
    #STATEMENT

#$sth.execute();

#my $arrayref = $sth.fetchall_arrayref();
#say $arrayref.elems; # 3

#my $sth = $dbh.prepare("SELECT datname FROM pg_database WHERE datistemplate = false;");
#$sth.execute();

#say $sth.fetchall_arrayref();

#$sth = $dbh.prepare(q:to/STATEMENT/);
    #INSERT INTO books
    #VALUES (?, ?)
    #STATEMENT

#my $book = to-json {
    #name => "The Fantastic Four",
    #author => {
        #first_name => "Jonas",
        #last_name => "The Invisible"
    #}
#};

#$sth.execute(1, $book);

my $sth = $dbh.prepare("SELECT data FROM books");
$sth.execute();

#say $sth.fetchall_arrayref();
my $res = $sth.fetchrow_hashref();
for (%$res) -> $x {
    my $json_data = from-json($x.value);
    say $json_data<name>;
}
$sth.finish;

$dbh.disconnect;
