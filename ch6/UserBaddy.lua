-- UserBaddy.lua
--
-- A subclass of Baddy that users can provide scripts for.
--

local Baddy = require 'Baddy'

-- TODO Define the next function in one place only.

-- Expect a Pair or a table; if it's a table, convert to a Pair.
local function pair(t)
  -- This calls Pair:new() only if t is a table.
  return (type(t) == 'table') and Pair:new(t) or t
end

local UserBaddy = Baddy:new({})

-- Set up a new baddy.
-- This expects a table with keys {home, color, chars, script}.
function UserBaddy:new(b)
  assert(b)  -- Require a table of initial values.
  b.pos        = b.home
  b.dir        = {-1, 0}
  b.get_dir    = loadfile(b.script)()
  self.__index = self
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
  local dir_index = self:get_dir(possible_dirs, grid, player)
  self.dir        = possible_dirs[dir_index] or possible_dirs[1]
  self.old_pos    = self.pos
  _, self.pos     = self:can_move_in_dir(self.dir, grid)
end

return UserBaddy
