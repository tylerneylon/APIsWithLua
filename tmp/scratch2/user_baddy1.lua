-- user_baddy1.lua

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
  if is_turn_pt then
    -- Choose a random direction that's not straight_i.
    local i = math.random(#possible_dirs)
    while i == straight_i do
      i = math.random(#possible_dirs)
    end
    dir = pair(possible_dirs[i])
    return i
  else
    return straight_i
  end
end
