-- Baddy.lua
--
-- A subclass of Character to capture behavior
-- specific to baddies.
--

local Character = require 'Character'

-- Set a new direction and simultaneously update baddy.next_dir
-- to be a right or left turn from new_dir.
-- This function cannot be seen outside the Baddy module.
local function set_new_dir(baddy, new_dir)
  baddy.dir = new_dir
  local sign = math.random(2) * 2 - 3  -- Either -1 or +1.
  baddy.next_dir = {sign * baddy.dir[2], -sign * baddy.dir[1]}
end

local Baddy = Character:new()

-- Set up a new baddy.
-- This expects a table with keys {home, color, chars}.
function Baddy:new(b)
  assert(b)  -- Require a table of initial values.
  b.pos        = b.home
  b.dir        = {-1, 0}
  b.next_dir   = {-1, 0}
  self.__index = self
  return setmetatable(b, self)
end

function Baddy:move_if_possible(grid)
  local deltas = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

  -- Try to change direction; otherwise the next_dir will take
  -- effect when we're at a turn in that direction.
  if self:can_move_in_dir(self.next_dir, grid) then
    set_new_dir(self, self.next_dir)
  end

  -- Try to move in self.dir; if that doesn't work, randomly
  -- change directions till we can move again.
  local can_move, new_pos = self:can_move_in_dir(self.dir, grid)
  while not can_move do
    set_new_dir(self, deltas[math.random(4)])
    can_move, new_pos = self:can_move_in_dir(self.dir, grid)
  end
  self.old_pos = self.pos  -- Save the old position.
  self.pos     = new_pos
end

return Baddy
