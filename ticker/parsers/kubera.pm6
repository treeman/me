use parser;

class Kubera does Parser {

    method update ($db) {
        my $url = 'http://kubera-tn.weebly.com/blog';
        say "Checking $url";
        my $html = download::site($url);
        #my $html = slurp("kubera.html");

        my $curr = self.parse($html);
        if self.is_new($db, $curr) {
            say "NEW %$curr<manga> s%$curr<season>e%$curr<chapter>";
            my $json = to-json(%$curr);
            $db.insert_event($json);
        }
    }

    method is_new ($db, $x) {
        my $sql = q:to/STATEMENT/;
            SELECT * FROM events
            WHERE object->>'manga' = 'Kubera'
            AND object->>'location' = ?
            ORDER BY object->>'ref_id' DESC LIMIT 1
            STATEMENT
        my $last = $db.select_one($sql, %$x<location>)<object>;
        return True unless $last;

        $last = from-json($last);

        return %$x<ref_id> > $last<ref_id>;
    }

    grammar Entry {
        token TOP { <naver_link> }

        rule naver_link {
            '<a href="' <url> '"'
            <attribute>*
            '>'
            <text>
            '</a>'
        }

        rule url {
            'http' s? '://'
            'www.'?
            'comic.naver.com/webtoon/detail.nhn?'
            'titleId=' <manga_id>
            '&amp;'
            'no=' <ch_id>
        }

        # TODO could allow parsing of others here?
        token manga_id { 131385 }
        token ch_id { \d+ }

        rule attribute {
            \w+ '="' <-["<>]>* \"
        }
        token text { <-[<>]>* }
    }

    grammar Name {
        rule TOP {
            ^ Season <season> Chapter <chapter> \- <title> $
        }

        token season { \d+ }
        token chapter { \d+ }
        token title { .+ }
    }

    # Only fetch the latest one
    method parse (Str $txt) {
        my $latest;
        for $txt ~~ m:exhaustive/ <Entry::TOP> / -> $m {
            my $name = Name.parse($m<Entry::TOP><naver_link><text>);

            my $info = [
                category => "manga",
                manga => "Kubera",
                season => ~$name<season>,
                chapter => ~$name<chapter>,
                title => ~$name<title>,
                location => "Babo Kim Scans",
                url => ~$m<Entry::TOP><naver_link><url>,
                ref_id => ~$m<Entry::TOP><naver_link><url><ch_id>,
            ];

            if !$latest || %$info<ref_id> > %$latest<ref_id> {
                $latest = $info;
            }
        }

        return $latest;
    }
};

