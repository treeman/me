use v6;
use Test;
BEGIN { @*INC.push: 'ticker' };

use parsers::naver;

my $actions = Naver::ChapterActions.new;

is Naver::Chapter.parse("84화", :$actions).made,
    %(chapter => 84), "Single chapter";
is Naver::Chapter.parse("192화", :$actions).made,
    %(chapter => 192), "Single chapter2";
is Naver::Chapter.parse("21부 10화", :$actions).made,
    %(season => 21, chapter => 10), "Short season + chapter";
is Naver::Chapter.parse("2부 153화", :$actions).made,
    %(season => 2, chapter => 153), "Short season + chapter2";
is Naver::Chapter.parse("3부 에피소드06 - 재정비 (01)", :$actions).made,
    %(season => 3, chapter => 6, title => "재정비 (01)"), "Other chapter format, with title";
is Naver::Chapter.parse("2부 에피소드27 - 마도사 에더마스크 (04)", :$actions).made,
    %(season => 2, chapter => 27, title => "마도사 에더마스크 (04)"),
        "Other chapter format, with title 2";
is Naver::Chapter.parse("에피소드12 <에디아(11)>", :$actions).made,
    %(chapter => 12, title => "<에디아(11)>"),
        "Other chapter format, with title without";

done()
