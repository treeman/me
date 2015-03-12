use v6;
use Test;
BEGIN { @*INC.push: 'ticker' };

use jagged;

my @stuff = (
    ["foo", "bar", "quux"],
    ["meepo3", 2313, "PRO"],
    [1, 2, 3],
    ["asdf12345", "pew", "pow"],
    ["asdf12345asdf"],
    ["bah", "bah", "bah", "bah", "bah"],
);

my @res = (
    "foo            bar   quux",
    "meepo3         2313  PRO",
    "1              2     3",
    "asdf12345      pew   pow",
    "asdf12345asdf",
    "bah            bah   bah   bah  bah");

is jagged_width(@stuff), [13, 4, 4, 3, 3], "Jagged width";
is jagged_width([]), [], "Jagged empty";
is jagged_width([[""]]), [0], "Jagged zero";

is balanced_width_columns(@stuff, 2), @res, "Balanced columns 1";
is balanced_width_columns([], 2), (""), "Balanced nothing";
is balanced_width_columns([["a"]], 2), ("a"), "Balanced ref one";
is balanced_width_columns([["a"], ["b"]], 2), ("a", "b"), "Balanced ref two";
is balanced_width_columns([["a", "aaaaa"], ["b"]], 2), ("a  aaaaa", "b"), "Balanced ref three?";
is balanced_width_columns([["a", "aaaaa"], ["b"]], 2), ["a  aaaaa", "b"], "Balanced ref ref?";

done()

