#use Grammar::Debugger;
#use Grammar::Tracer;
use parser;

class Naver does Parser {

    method update ($db, $conf) {
        for (@($conf<naver>)) -> $x {
            self.update_series($db, $x<id>, $x<title>);
        }
    }

    method update_series ($db, Int $title_id, Str $manga) {
        my $url = "http://comic.naver.com/webtoon/list.nhn?titleId=$title_id";
        say "Checking $url";
        my $html = download::site($url);

        my @parsed = self.parse($html, $manga);
        for (@parsed) -> $info {
            if self.is_new($db, $info) {
                my $descr = "e$info<chapter>";
                $descr = "s$info<season>" ~ $descr if $info<season>;
                say "NEW $info<manga> $descr";
                my $json = to-json(%$info);
                $db.insert_event($json);
            }
        }
    }

    method is_new ($db, $x) {
        my $sql = q:to/STATEMENT/;
            SELECT 1 FROM events
            WHERE object->>'manga' = ?
            AND object->>'location' = ?
            AND object->>'ref_id' = ?
            LIMIT 1
            STATEMENT
        my @last = $db.select($sql, $x<manga>, $x<location>, $x<ref_id>);
        return @last.elems == 0;
    }

    grammar Entry {
        token TOP { <naver_link> }

        rule naver_link {
            '<a href="' <url> '"'
            <attribute>*
            '>'
            #<name>
            <text>
            '</a>'
        }

        rule url {
            '/webtoon/detail.nhn?'
            'titleId=' <manga_id>
            '&'
            'no=' <ch_id>
            '&weekday=' \w+
        }

        token manga_id { \d+ }
        token ch_id { \d+ }

        rule attribute {
            \w+ '="' <-["<>]>* \"
        }
        token text { <-[<>]>* }
    }

    grammar Chapter {
        rule TOP {
            ^ <short_descr> | <long_descr> $
        }
        token short_descr {
            [<season> 부]? \s*
            <chapter> 화 \s*
        }
        token long_descr {
            [<season> 부]? \s*
            에피소드 <chapter> \s*
            [[\- \s+]? <title>]?
        }
        token season { \d+ }
        token chapter { \d+ }
        token title { .+ }
    }

    class ChapterActions {
        method TOP($/) {
            $/.make: $<short_descr>.made // $<long_descr>.made;
        }

        method short_descr($/) {
            my %res;

            my $season = $<season>.made;
            %res<season> = $season if $season;
            %res<chapter> = $<chapter>.made;

            $/.make: %res;
        }
        method long_descr($/) {
            my %res;

            my $season = $<season>.made;
            my $title = $<title>.made;
            %res<season> = $season if $season;
            %res<chapter> = $<chapter>.made;
            %res<title> = $title;

            $/.make: %res;
        }
        method season($/) { $/.make: +$/ }
        method chapter($/) { $/.make: +$/ }
        method title($/) { $/.make: ~$/ }
    }

    # Only fetch the latest one
    method parse (Str $txt, Str $manga) {
        my @res;
        for $txt ~~ m:exhaustive/ <Entry::TOP> / -> $m {
            # Use a separate parser for chapter parsing,
            # so we can use an actions object.
            my $ch_txt = ~$m<Entry::TOP><naver_link><text>;
            my $actions = ChapterActions.new;
            my $chapter_info = Chapter.parse($ch_txt, :$actions);

            if !$chapter_info {
                say "Skipping chapter: `$ch_txt` for $manga as we couldn't parse it.";
                next;
            }
            $chapter_info = $chapter_info.made;

            my $info = {
                category => "manga",
                manga => $manga,
                location => "Naver",
                url => 'http://comic.naver.com' ~ ~$m<Entry::TOP><naver_link><url>,
                ref_id => ~$m<Entry::TOP><naver_link><url><ch_id>,
                %$chapter_info
            };
            @res.push($info);
        }

        return @res;
    }
};

