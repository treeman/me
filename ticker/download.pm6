module download;

# Could possibly use LWP::Simple or something,
# but ssl doesn't work...?
our sub site (Str $url) {
    # This breaks with non utf-8 sites.
    #my $html = qq:x/curl "$url"/;
    #return $html;

    return non_utf8_site($url);
}

sub get_encoding (Str $file) {
    my $encoding = qq:x/file -i $file/;
    if $encoding ~~ / charset \= (\S+) / {
        return ~$0;
    }
    else {
        warn "WARNING could not get encoding for `$file`";
        return "";
    }
}

sub non_utf8_site (Str $url) {
    # TODO how to automatically generate?
    my $tmpfile = "$*TMPDIR/tmp_download.html";

    my $exit_code = run 'curl', '-o', $tmpfile, $url;
    if $exit_code == 0 {

        my $encoding = get_encoding($tmpfile);
        my $html = qq:x/iconv -f $encoding -t UTF-8 $tmpfile/;

        unlink($tmpfile);

        return $html;
    }
    else {
        warn "WARNING curl failed to download `$url`";
        return "";
    }
}
