-- a_user_baddy.lua

-- Return the dot product of vectors a and b.
local function dot(a, b)
  return a[1] * b[1] + a[2] * b[2]
end

local direction = pair {1, 0}
local num_turns = 0

-- The next function will return true when:
--  * The player can turn left or right; or
--  * the player can't go straight ahead.
-- Intuitively, a "turning point" is any good place to consider
-- moving in a new direction.
local function is_turning_point(possible_dirs)

  local backwards       = pair {-direction.x, -direction.y}
  local can_go_straight = false

  for i, possible_dir in pairs(possible_dirs) do
    if possible_dir == direction then
      can_go_straight = true
    elseif possible_dir ~= backwards then
      return true  -- We can turn left or right.
    end
  end

  -- If we get here, then turning left or right is impossible.
  return not can_go_straight
end

local function choose_direction(baddy, possible_dirs,
                                grid, player)

  -- If we can't turn and we can go straight, then go straight.
  if not is_turning_point(possible_dirs) then
    return direction
  end

  -- Every 5th turn is random.
  num_turns = num_turns + 1
  if num_turns % 5 == 0 then
    direction = possible_dirs[math.random(#possible_dirs)]
    return direction
  end

  -- Try to go toward the player in the other 4 out of 5 turns.
  
  local to_player = pair {player.pos[1] - baddy.pos[1],
                          player.pos[2] - baddy.pos[2]}

  local max_dot_prod = -math.huge

  for i, possible_dir in pairs(possible_dirs) do
    local dot_prod = dot(possible_dir, to_player)
    if dot_prod > max_dot_prod then
      max_dot_prod = dot_prod
      direction    = possible_dir
    end
  end

  return direction
end

return choose_direction
