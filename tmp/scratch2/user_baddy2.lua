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

-- Return true iff either we can no longer move forward, or if
-- a left or right turn is available.
local function is_turning_point(possible_dirs)

  local backwards       = pair {-dir.x, -dir.y}
  local can_go_straight = false
  local can_turn        = false
  local straight_i      = 0

  for i, possible_dir in pairs(possible_dirs) do
    if possible_dir == dir then
      can_go_straight = true
      straight_i      = i
    elseif possible_dir ~= backwards then
      can_turn = true
    end
  end

  return can_turn or not can_go_straight, straight_i
end


return function (baddy, possible_dirs, grid, player)

  local is_turn_pt, straight_i = is_turning_point(possible_dirs)

  if not is_turn_pt then
    return straight_i
  end

  local to_player = pair {player.pos[1] - baddy.pos[1],
                          player.pos[2] - baddy.pos[2]}

  local max_dot_prod = -math.huge
  local choice_i     = 0

  for i, possible_dir in pairs(possible_dirs) do
    local dot_prod = dot(possible_dir, to_player)
    if dot_prod > max_dot_prod then
      max_dot_prod = dot_prod
      choice_i = i
    end
  end

  if math.random(3) == 1 then
    choice_i = math.random(#possible_dirs)
  end
  dir = possible_dirs[choice_i]
  return choice_i

  --[[
  local i = math.random(#possible_dirs)
  dir = possible_dirs[i]
  return i
  --]]
end
