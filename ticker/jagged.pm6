module jagged;

# Take a jagged list of lists and produce a list of strings
# left adjusted to the same width, with $space between columns.
sub balanced_width_columns (@jagged, $space) is export {
    my @width = jagged_width(@jagged);

    return map {
        my $row = "";
        loop (my $i = 0; $i < @$_; ++$i) {
            my $val = @$_[$i];
            my $width = @width[$i] + $space;
            $row ~= $val ~ " " x $width - $val.chars();
        }
        $_ = $row.trim();
    }, @jagged;
}

sub jagged_width (@jagged) is export {
    my @width;

    #loop (my $i = 0; $i < @stuff; ++$i) {
    for (@jagged) -> $row {
        loop (my $j = 0; $j < @$row; ++$j) {
            my $s = ~@$row[$j];
            if !@width[$j] || $s.chars() > @width[$j] {
                @width[$j] = $s.chars();
            }
        }
    }
    return @width;
}
