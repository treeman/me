use JSON::Tiny;
say from-json('{ "a": 42 }').perl;
say to-json { a => [1, 2, 'b'] };
