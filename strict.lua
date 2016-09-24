--[[ strict.lua

Tested with Lua 5.2 and 5.3; not designed for 5.1 or earlier.

After the user makes the following statement:

    local _ENV = strict.new_env(),

their code will throw an error on either of these conditions:

 * A global variable is created from a nested code block, such
   as within a function, or
 * An undeclared global is referenced.

There are a number of files similar to this one available
online, as well as described in the Programming in Lua book.
This happens to be a version that I like.

--]]

local strict = {}

-- This returns a replacement for _ENV that detects errors.
function strict.new_env()

  -- Set up the new environment with the values from _ENV.
  local env = {}
  for key, value in pairs(_ENV) do
    env[key] = value
  end

  -- Set up env's metatable. Define the metamethods inline so
  -- they can refer to `declared` as an upvalue.
  local mt = {}
  local declared = {}

  -- Throw an error for global assigments in non-main Lua code.
  mt.__newindex = function (t, k, v)
    if not declared[k] then
      -- The values (2, 'S') ask for (S for) source info on the
      -- function at level 2 in the stack; the one making the
      -- assignment.
      local w = debug.getinfo(2, 'S').what
      if w ~= 'main' and w ~= 'C' then
        local fmt = 'Assignment to undeclared global "%s"'
        -- The value 2 will blame the error on the code making
        -- the bad assignment; i.e. the caller of __newindex().
        error(fmt:format(k), 2)
      end
      declared[k] = true
    end
    -- Make the actual assignment in the table t.
    rawset(t, k, v)
  end

  -- Throw an error for references to undeclared global names.
  mt.__index = function (t, k)
    if not declared[k] then
      -- The parameter 2 will blame the error on the code making
      -- the bad lookup; i.e. the caller of __index().
      error(('Use of undeclared global "%s"'):format(k), 2)
    end
    -- We won't always get an error; finish the lookup on key k.
    return rawget(t, k)
  end

  -- Return the new environment `env`.
  return setmetatable(env, mt)
end

return strict