-- UserBaddy.lua
--
-- A subclass of Baddy that users can provide scripts for.
--

local Baddy = require 'Baddy'

local function is_in_table(needle, haystack)
  for _, value in pairs(haystack) do
    if value == needle then
      return true
    end
  end
  return false
end

local UserBaddy = Baddy:new({})

-- Set up a new baddy.
-- This expects a table with keys {home, color, chars, script}.
function UserBaddy:new(b)
  assert(b)  -- Require a table of initial values.
  b.pos           = b.home
  b.dir           = {-1, 0}
  b.get_direction = loadfile(b.script)()
  self.__index    = self
  return setmetatable(b, self)
end

function UserBaddy:move_if_possible(grid, player)

  -- Determine which directions are possible to move in.
  local deltas = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
  local possible_dirs = {}
  for _, delta in pairs(deltas) do
    if self:can_move_in_dir(delta, grid) then
      table.insert(possible_dirs, pair(delta))
    end
  end

  -- Call the user-defined movement function.
  -- The `self` value will become the first parameter sent in.
  self.dir = self:get_direction(possible_dirs, grid, player)

  if not is_in_table(self.dir, possible_dirs) then
    self.dir = possible_dirs[1]
  end

  -- Update our position and saved old position.
  self.old_pos = self.pos
  _, self.pos  = self:can_move_in_dir(self.dir, grid)
end

return UserBaddy
