-- eatyguy9.lua

local eatyguy = {}


-- Require modules.

local Baddy  = require 'Baddy'
local strict = require 'strict'


-- Enter strict mode.

local _ENV = strict.new_env()


-- Convenience functions.

-- Expect a Pair or a table; if it's a table, convert to a Pair.
local function pair(t)
  -- This calls Pair:new() only if t is a table.
  return (type(t) == 'table') and Pair:new(t) or t
end


-- Globals.

local percent_extra_paths = 15
local grid                = nil     -- grid[x][y]: falsy = wall.
local grid_w, grid_h      = nil, nil
local player = Character:new({pos      = pair{1, 1},
                              dir      = pair{1, 0},
                              next_dir = pair{1, 0}})
local baddies = {}
-- The game ends as soon as end_msg is set to any string; that
-- string will be printed to the user as a farewell message.
local end_msg = nil


-- Internal functions.

local function is_in_bounds(pt)
  return (1 <= pt.x and pt.x <= grid_w and
          1 <= pt.y and pt.y <= grid_h)
end

local function get_neighbor_directions(pt, percent_extra)
  -- percent_extra is the percent chance of adding extra paths.
  percent_extra = percent_extra or 0
  local neighbor_directions = {}
  local all_directions = {pair{1, 0}, pair{-1, 0},
                          pair{0, 1}, pair{0, -1}}
  for _, direction in pairs(all_directions) do
    local n_pt = pt + direction * 2  -- The neighbor point.
    local is_extra_ok = (math.random(100) <= percent_extra)
    -- Add `direction` if the neighbor is not yet in a path, or
    -- if we randomly got an extra ok using percent_extra.
    if is_in_bounds(n_pt) and
       (not grid[n_pt.x][n_pt.y] or is_extra_ok) then
      table.insert(neighbor_directions, direction)
    end
  end
  return neighbor_directions
end

local function drill_path_from(pt)
  grid[pt.x][pt.y] = '. '
  local neighbor_directions = get_neighbor_directions(pt)
  while #neighbor_directions > 0 do
    local direction = table.remove(neighbor_directions,
                          math.random(#neighbor_directions))
    grid[pt.x + direction.x][pt.y + direction.y] = '. '
    drill_path_from(pt + direction * 2)
    neighbor_directions = get_neighbor_directions(pt,
                                          percent_extra_paths)
  end
end

local function check_for_death()
  for _, baddy in pairs(baddies) do
    if pair(player.pos) == pair(baddy.pos) then
      end_mgs = 'Game over!'
    end
  end
end

local move_delta     = 0.2  -- seconds
local next_move_time = nil

local function update(state)

  -- Ensure any dot under the player has been eaten.
  local pt = pair(player.pos)
  grid[pt.x][pt.y] = '  '

  -- Update the next direction if an arrow key was pressed.
  local direction_of_key = {left  = pair{-1, 0},
                            right = pair{1, 0},
                            up    = pair{0, -1},
                            down  = pair{0, 1}}
  local new_dir = direction_of_key[state.key]
  if new_dir then player.next_dir = new_dir end

  -- Only move every move_delta seconds.
  if next_move_time == nil then
    next_move_time = state.clock + move_delta
  end
  if state.clock < next_move_time then return end
  next_move_time = next_move_time + move_delta

  -- It's been at least move_delta seconds since the last
  -- time things moved, so let's move them now!
  player:move_if_possible(grid)
  -- Check for baddy collisions both now and after baddies have
  -- moved. With only one check, it may miss the case where both
  -- player and baddy move past each other in one time step.
  check_for_death()
  for _, baddy in pairs(baddies) do
    baddy:move_if_possible(grid)
  end
  check_for_death()
end

local function draw(clock)

  -- Choose the sprite to draw. For example, a right-facing
  -- player is drawn as '< alternated with '-
  local draw_data = {
    [ '1,0'] = {"'<", "'-"},
    ['-1,0'] = {">'", "-'"},
    [ '0,1'] = {"^'", "|'"},
    ['0,-1'] = {"v.", "'."}
  }
  local anim_timestep = 0.2
  local dirkey = ('%d,%d'):format(player.dir[1],
                                  player.dir[2])
  -- framekey switches between 1 & 2; basic sprite animation.
  local framekey = math.floor(clock / anim_timestep) % 2 + 1
  player.chars   = draw_data[dirkey][framekey]

  -- Draw the player and baddies.
  player:draw(grid)
  for _, baddy in pairs(baddies) do
    baddy:draw(grid)
  end
end


-- Public functions.

function eatyguy.init()

  -- Set up the grid size and pseudorandom number generation.
  grid_w, grid_h = 39, 21
  math.randomseed(os.time())

  -- Set up the baddies.
  local baddy_info = { {color = 1, chars = 'oo', pos = {1, 1}},
                       {color = 2, chars = '@@', pos = {1, 0}},
                       {color = 5, chars = '^^', pos = {0, 1}} }
  for _, info in pairs(baddy_info) do
    info.home = pair{(grid_w - 1) * info.pos[1] + 1,
                     (grid_h - 1) * info.pos[2] + 1}
    table.insert(baddies, Baddy:new(info))
  end

  -- Build the maze.
  grid = {}
  for x = 1, grid_w do grid[x] = {} end
  drill_path_from(pair{1, 1})

  -- Draw the maze.
  set_color('f', 7)                  -- White foreground.
  for y = 0, grid_h + 1 do
    for x = 0, grid_w + 1 do
      if grid[x] and grid[x][y] then
        set_color('b', 0)            -- Black; open space color.
        io.write(grid[x][y])
      else
        set_color('b', 4)            -- Blue; wall color.
        io.write('  ')
      end
      io.flush()                     -- Needed for color output.
    end
    set_color('b', 0)                -- End the lines in black.
    io.write(' \r\n')                -- Move cursor to next row.
  end
end

function eatyguy.loop(state)
  update(state)
  draw(state.clock)
  return end_msg
end

return eatyguy
