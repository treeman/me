use plugins::plugin;

class Test does Plugin {
    method update ($db) {
        say "in Test::update";
    }
};

