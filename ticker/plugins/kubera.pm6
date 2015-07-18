use plugins::plugin;

class Kubera does Plugin {

    method update ($db) {
        #my $url = 'http://kubera-tn.weebly.com/blog';
        #say "Checking $url";
        #my $html = download::site($url);
        my $html = slurp("kubera.html");

        self.parse($html);
        #my @new = self.filter_new($db, @upcoming);
        #for (@new) -> $x {
            #say "NEW %$x<product> (%$x<status>:-)";
            #my $json = to-json(%$x);
            #$db.insert_event($json);
        #}
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

        say $latest;
    }
};

