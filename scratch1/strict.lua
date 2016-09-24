--[[ strict.lua

Throw an error when a global is defined in a function or when an
undeclared global is referenced in a function.

There are a number of files similar to this one available
online, as well as described in the Programming in Lua book.
This is based on all of those influences.

--]]

local mt = getmetatable(_G)

-- This module adds hooks so that every global assignment
-- results in a call to mt.__newindex(), and every failed global
-- variable lookup results in a call to mt.__index(). This hooks
-- live in the metatable of _G, the table of all globals.
if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end

-- This will hold all known global names as keys. This is useful
-- because it remembers values that have been declared, but
-- whose values have been set to nil; _G itself forgets those.
mt.__declared = {}

local function what ()
  -- The user code will be at level 3 in the stack when this
  -- calls debug.getinfo(). This text diagram dhows how the user
  -- code counts as level 3:
  --     Code:  <user> -> mt.fn() -> what() -> debug.get_info()
  --     Level:   3         2          1            0
  -- The string 'S' means we're asking for 'source' debug info,
  -- which includes the value of d.what.
  local d = debug.getinfo(3, 'S')
  -- The value of d.what, if present, will be either 'Lua', 'C',
  -- or 'main'. If unknown, then give the user the benefit of
  -- the doubt that they are running C code; this guess avoids
  -- throwing errors on correct code.
  return d and d.what or 'C'
end

-- Throw an error for global assigments in non-main Lua code.
mt.__newindex = function (t, k, v)
  if not mt.__declared[k] then
    local w = what()
    if w ~= 'main' and w ~= 'C' then
      local fmt = 'Attempt to assign to undeclared global "%s"'
      -- The parameter 2 will blame the error on the code making
      -- the bad assignment; i.e. the caller of __newindex().
      error(fmt:format(k), 2)
    end
    mt.__declared[k] = true
  end
  -- Make the actual assignment in the table t = _G.
  rawset(t, k, v)
end

-- Throw an error for references to undeclared global names.
mt.__index = function (t, k)
  if not mt.__declared[k] and what() ~= "C" then
    -- The parameter 2 will blame the error on the code making
    -- the bad lookup; i.e. the caller of __index().
    error(('Use of undeclared global "%s"'):format(k), 2)
  end
  -- We won't always get an error; finish the lookup on key k.
  return rawget(t, k)
end
