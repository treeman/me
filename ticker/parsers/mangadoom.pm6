#use Grammar::Debugger;
#use Grammar::Tracer;
use parser;

class Mangadoom does Parser {

    method update ($db, $conf) {
        my $url = "http://mangadoom.co/latest-releases/";
        say "Checking $url";
        my $html = download::site($url);
        #my $html = slurp("doom.html");

        my @parsed = self.parse($html);

        # Lookup mangas in a hash
        my %mangas;
        for (@($conf<manga>)) -> $x { %mangas{$x} = 1 }

        for (@parsed) -> $info {
            unless %mangas{$info<manga>} { next };

            if self.is_new($db, $info) {
                say "NEW $info<manga> $info<chapter>";
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
            AND object->>'url' = ?
            LIMIT 1
            STATEMENT
        my @last = $db.select($sql, $x<manga>, $x<location>, $x<url>);
        return @last.elems == 0;
    }

    grammar Entry {
        rule TOP {
            <manga_link>
            <ch_link>
        }

        rule manga_link {
            '<a class="mng"'
            'href="' <url> '"'
            <attribute>*
            '>'
            <text>
            <hot>?
            '</a>'
        }

        rule hot {
            '<b class="hot_sts">Hot</b>' 
        }

        rule ch_link {
            '<a class="mng_chp"'
            'href="' <url> '"'
            <attribute>*
            '>'
            <text>
            '</a>'
        }

        rule url {
            'http://mangadoom.co'
            <-["<>]>+
        }

        rule attribute {
            \w+ '="' <-["<>]>* '"'
        }
        token text { <-[<>]>* }
    }

    grammar Chapter {
        token TOP { ^ .+? \s+ <chapter> $ }
        #token name { .+ }
        rule chapter { <ch>v<version> | <ch>'.'<version> | <ch> }
        token ch { \d+ }
        token version { \d+ }
    }

    class ChapterActions {
        method TOP($/) {
            $/.make: $<chapter>.made;
        }

        method chapter($/) {
            my %res = %(chapter => $<ch>.made);
            my $version = $<version>.made;
            %res<version> = $version if $version;

            $/.make: %res;
        }

        method ch($/) {  $/.make: +$/ }
        method version($/) { $/.make: ~$/ }
        method name($/) { $/.make: +$/}
    }

    # Only fetch the latest one
    method parse (Str $txt) {
        my @res;
        for $txt ~~ m:exhaustive/ <Entry::TOP> / -> $m {
            # Use a separate parser for chapter parsing,
            # so we can use an actions object.
            my $ch_txt = ~$m<Entry::TOP><ch_link><text>;
            my $actions = ChapterActions.new;
            #my $chapter_info = Chapter.parse($ch_txt);
            my $chapter_info = Chapter.parse($ch_txt, :$actions);
            my $manga = ~$m<Entry::TOP><manga_link><text>.trim();

            if !$chapter_info {
                say "Skipping chapter: `$ch_txt` for $manga as we couldn't parse it.";
                next;
            }
            $chapter_info = $chapter_info.made;

            my $info = {
                category => "manga",
                manga => $manga,
                location => "Mangadoom",
                url => ~$m<Entry::TOP><ch_link><url>.trim(),
                %$chapter_info
            };
            @res.push($info);
        }

        return @res;
    }
};

