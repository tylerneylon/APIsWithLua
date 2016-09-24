--[[ strict.lua

After the user makes the following statement:

    local _ENV = strict.begin(),

their code will throw an error on either of these conditions:

 * A global variable is created from a nested code block such
   as within a funciton, or
 * An undeclared global is referenced.

There are a number of files similar to this one available
online, as well as described in the Programming in Lua book.
This happens to be a version that I like.

--]]

local strict = {}


-- Internal functions.

local function what ()
  -- The user code will be at level 3 in the stack when this
  -- calls debug.getinfo(). This text diagram shows how the user
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


-- Call this function like so to begin strict mode:
--    local _ENV = strict.begin()
function strict.begin()

  -- Set up the new environment with the values from _G.
  local env = {}
  for k, v in pairs(_ENV) do
    env[k] = v
  end

  -- Set up env's metatable. Define the metamethods inline so
  -- they can refer to `declared` as an upvalue.
  local mt = {}
  local declared = {}

  -- Throw an error for global assigments in non-main Lua code.
  mt.__newindex = function (t, k, v)
    print(('__newindex(%s, %s, %s)'):format(tostring(t),
          tostring(k), tostring(v)))
    if not declared[k] then
      local w = what()
      print('  w = ' .. w)
      if w ~= 'main' and w ~= 'C' then
        local fmt = 'Assignment to undeclared global "%s"'
        -- The value 2 will blame the error on the code making
        -- the bad assignment; i.e. the caller of __newindex().
        error(fmt:format(k), 2)
      end
      declared[k] = true
    end
    -- Make the actual assignment in the table t = _G.
    rawset(t, k, v)
  end

  -- Throw an error for references to undeclared global names.
  mt.__index = function (t, k)
    if not declared[k] and what() ~= "C" then
      -- The parameter 2 will blame the error on the code making
      -- the bad lookup; i.e. the caller of __index().
      error(('Use of undeclared global "%s"'):format(k), 2)
    end
    -- We won't always get an error; finish the lookup on key k.
    return rawget(t, k)
  end

  return setmetatable(env, mt)
end

return strict