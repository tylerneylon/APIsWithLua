-- Baddy.lua
--
-- A subclass of Character to capture behavior
-- specific to baddies.
--

local Character = require 'Character'

Baddy = Character:new()

-- Expect a table with keys {home, color, chars}
function Baddy:new(b)
  assert(b)  -- Require a table of initial values.
  b.pos        = b.home
  b.dir        = {-1, 0}
  b.next_dir   = {-1, 0}
  self.__index = self
  return setmetatable(b, self)
end

function Baddy:abc()
end

return Baddy
