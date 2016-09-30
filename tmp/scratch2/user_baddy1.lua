-- user_baddy1.lua

-- Expect a Pair or a table; if it's a table, convert to a Pair.
local function pair(t)
  -- This calls Pair:new() only if t is a table.
  return (type(t) == 'table') and Pair:new(t) or t
end

local function dot(a, b)
  return a[1] * b[1] + a[2] * b[2]
end

local function s(pt)
  return tostring(pt[1]) .. ', ' .. tostring(pt[2])
end

local dir = pair {1, 0}

return function (baddy, possible_dirs, grid, player)

  local to_player = pair {player.pos[1] - baddy.pos[1],
                          player.pos[2] - baddy.pos[2]}
  io.stderr:write('to_player = ' .. s(to_player) .. '\n')
  local max_dot_prod = 0
  local best_i       = 0

  for i, possible_dir in pairs(possible_dirs) do
    io.stderr:write('possible_dir = ' .. s(possible_dir) .. '\n')
    local dot_prod = dot(possible_dir, to_player)
    io.stderr:write('dot_prod = ' .. dot_prod .. '\n')
    if dot_prod > max_dot_prod then
      max_dot_prod = dot_prod
      best_i = i
      io.stderr:write('best_i = ' .. best_i .. '\n')
    end
    --[[
    if dir == possible_dir then
      return i
    end
    --]]
  end
  return best_i

  --[[
  local i = math.random(#possible_dirs)
  dir = possible_dirs[i]
  return i
  --]]
end
