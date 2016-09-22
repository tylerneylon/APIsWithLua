I'm thinking that what is now eatyguy9 can contain some mistakes that are
noticed by checks introduced in chapter 5.

Perhaps eatyguy10 can be the final version, and can include a (not yet added)
hook or small set of hooks so that users can implement their own behavior for
baddies.

One possible interface is:

function get_dir_to_move_in(possible_dirs, grid, player, baddy)
 -- Return an index in [1, #possible_dirs]. Any other return value results in no
 -- movement.
end
