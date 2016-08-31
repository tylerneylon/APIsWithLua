-- Character.lua
--
-- A class to capture behavior of general
-- characters. Both the player and baddies
-- may be subclasses.
--

Character = {}

function Character:new(c)
  c = c or {}
  self.__index = self
  return setmetatable(c, self)
end

function Character:can_move_in_dir(dir, grid)
  local p = self.pos
  local gx, gy = p[1] + dir[1], p[2] + dir[2]
  return (grid[gx] and grid[gx][gy]), {gx, gy}
end

function Character:draw()
  -- Draw the player.
  set_color('b', 3)  -- Yellow background.
  set_color('f', 0)  -- Black foreground.
  local x = 2 * self.pos[1]
  local y =     self.pos[2]
  set_pos(x, y)
  io.write(self.chars)
  io.flush()

  -- Erase the old player pos if appropriate.
  if self.old_pos then
    local x = 2 * self.old_pos[1]
    local y =     self.old_pos[2]
    set_pos(x, y)
    set_color('b', 0)  -- Black background.
    io.write('  ')
    io.flush()
    self.old_pos = nil
  end
end

return Character
