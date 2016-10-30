-- eatyguy10.lua

local eatyguy = {}


-- Require modules.

local Baddy     = require 'Baddy'
local UserBaddy = require 'UserBaddy'
local strict    = require 'strict'


-- Enter strict mode.

local _ENV = strict.new_env()


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

local function get_nbor_dirs(pt, perc_extra)
  -- perc_extra is the percent chance of including extra paths.
  perc_extra = perc_extra or 0
  local nbor_dirs = {}
  local all_dirs = {pair{1, 0}, pair{-1,  0},
                    pair{0, 1}, pair{ 0, -1}}
  for _, dir in pairs(all_dirs) do
    local n_pt = pt + dir * 2  -- The nbor point.
    local is_extra_ok = (math.random(100) <= perc_extra)
    -- Add `dir` if the nbor is not yet in a path, or if we
    -- randomly got an extra ok using perc_extra.
    if is_in_bounds(n_pt) and
       (not grid[n_pt.x][n_pt.y] or is_extra_ok) then
      table.insert(nbor_dirs, dir)
    end
  end
  return nbor_dirs
end

local function drill_path_from(pt)
  grid[pt.x][pt.y] = '. '
  local nbor_dirs = get_nbor_dirs(pt)
  while #nbor_dirs > 0 do
    -- Drill recursively in a random direction from nbor_dirs.
    local dir = table.remove(nbor_dirs, math.random(#nbor_dirs))
    grid[pt.x + dir.x][pt.y + dir.y] = '. '
    drill_path_from(pt + dir * 2)
    nbor_dirs = get_nbor_dirs(pt, percent_extra_paths)
  end
end

local function check_for_death()
  for _, baddy in pairs(baddies) do
    if pair(player.pos) == pair(baddy.pos) then
      end_msg = 'Game over!'
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
  local dir_of_key = {left = pair{-1,  0}, right = pair{1, 0},
                      up   = pair{ 0, -1}, down  = pair{0, 1}}
  local new_dir = dir_of_key[state.key]
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
    baddy:move_if_possible(grid, player)
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
  local dirkey   = ('%d,%d'):format(player.dir[1],
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
  local baddy_info = { {color = 1, chars = 'oo', pos = {1, 1},
                        script = 'user_baddy2.lua'},
                       {color = 2, chars = '@@', pos = {1, 0},
                        script = 'user_baddy2.lua'},
                       {color = 5, chars = '^^', pos = {0, 1},
                        script = 'user_baddy1.lua'} }
  for _, info in pairs(baddy_info) do
    info.home = pair{(grid_w - 1) * info.pos[1] + 1,
                     (grid_h - 1) * info.pos[2] + 1}
    table.insert(baddies, UserBaddy:new(info))
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
