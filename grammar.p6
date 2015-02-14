grammar Legal-Module-Name
{
    token TOP
    {
        ^ <identifier> [<separator><identifier>] ** 0..* $
    }
    token identifier
    {
        # Leading alpha or _ only
        <[A..Za..z_]>
        <[A..Za..z0..9]> ** 0..*
    }
    token separator
    {
        \:\: # colon pairs
    }
}

#my $proposed_module_name = 'Super::New::Module';
my $proposed_module_name = 'Super::New::Module::a::_a::b2';

{
    my $match_obj = Legal-Module-Name.parse($proposed_module_name);

    if $match_obj {
        say $match_obj;
    }
    else {
        say 'Invalid';
    }

    say $match_obj<identifier>[0].Str;

    say $match_obj<identifier>;
}

class Module::Name::Actions
{
    method TOP($/)
    {
        if $<identifier>.elems > 5 {
            warn 'There are a many identifiers!';
        }
    }
}

my $actions = Module::Name::Actions.new;
my $match_obj = Legal-Module-Name.parse($proposed_module_name, :actions($actions));
