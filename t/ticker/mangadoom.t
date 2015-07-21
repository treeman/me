use v6;
use Test;
BEGIN { @*INC.push: 'ticker' };

use parsers::mangadoom;

my $actions = Mangadoom::ChapterActions.new;

#my $x = Mangadoom::Chapter.parse("Kingdom 439v000", :$actions);
#say $x;
#say $x.made;

is Mangadoom::Chapter.parse("Battle Through The Heavens 85", :$actions).made,
    %(chapter => 85), "Regular";
is Mangadoom::Chapter.parse("Kingdom 439v000", :$actions).made,
    %(chapter => 439, version => "000"), "Version1";
is Mangadoom::Chapter.parse("History's Strongest Disciple Kenichi 583.005", :$actions).made,
    %(chapter => 583, version => "005"), "Version2";

done()

