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

function Character:move_if_possible(grid)
  -- Change direction if we can; otherwise the next_dir will take effect if we
  -- hit a corner where we can turn in that direction.
  if self:can_move_in_dir(self.next_dir, grid) then
    self.dir = self.next_dir
  end

  -- Move in direction self.dir if possible.
  local can_move, new_pos = self:can_move_in_dir(self.dir, grid)
  if can_move then
    self.old_pos = self.pos  -- Save the old position.
    self.pos     = new_pos
  end
end

function Character:draw(grid)
  -- Draw the character.
  local color = self.color or 3  -- Default to yellow.
  set_color('b', color)
  set_color('f', 0)  -- Black foreground.
  local x = 2 * self.pos[1]
  local y =     self.pos[2]
  set_pos(x, y)
  io.write(self.chars)
  io.flush()

  -- Erase the old character pos if appropriate.
  if self.old_pos then
    local op = self.old_pos
    local x  = 2 * op[1]
    local y  =     op[2]
    set_pos(x, y)
    set_color('f', 7)  -- White foreground.
    set_color('b', 0)  -- Black background.
    io.write(grid[op[1]][op[2]])
    io.flush()
    self.old_pos = nil
  end
end

return Character
