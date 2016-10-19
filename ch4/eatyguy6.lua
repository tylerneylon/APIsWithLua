-- eatyguy6.lua

local eatyguy = {}


-- Globals.

local percent_extra_paths = 15
local grid                = nil     -- grid[x][y]: falsy = wall.
local grid_w, grid_h      = nil, nil
local player = Character:new({pos      = {1, 1},
                              dir      = {1, 0},
                              next_dir = {1, 0}})


-- Internal functions.

local function is_in_bounds(x, y)
  return (1 <= x and x <= grid_w and
          1 <= y and y <= grid_h)
end

local function get_nbor_dirs(x, y, perc_extra)
  -- perc_extra is the percent chance of including extra paths.
  perc_extra = perc_extra or 0
  local nbor_dirs = {}
  local all_dirs = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
  for _, dir in pairs(all_dirs) do
    local nx, ny = x + 2 * dir[1], y + 2 * dir[2]
    local is_extra_ok = (math.random(100) <= perc_extra)
    -- Add `dir` if the nbor is not yet in a path, or if we
    -- randomly got an extra ok using perc_extra.
    if is_in_bounds(nx, ny) and
       (not grid[nx][ny] or is_extra_ok) then
      table.insert(nbor_dirs, dir)
    end
  end
  return nbor_dirs
end

local function drill_path_from(x, y)
  grid[x][y] = '. '
  local nbor_dirs = get_nbor_dirs(x, y)
  while #nbor_dirs > 0 do
    local dir = table.remove(nbor_dirs, math.random(#nbor_dirs))
    grid[x + dir[1]][y + dir[2]] = '. '
    drill_path_from(x + 2 * dir[1], y + 2 * dir[2])
    nbor_dirs = get_nbor_dirs(x, y, percent_extra_paths)
  end
end

local move_delta     = 0.2  -- seconds
local next_move_time = nil

local function update(state)

  -- Ensure any dot under the player has been eaten.
  local p = player.pos
  grid[p[1]][p[2]] = '  '

  -- Update the next direction if an arrow key was pressed.
  local dir_of_key = {left = {-1, 0}, right = {1, 0},
                      up   = {0, -1}, down  = {0, 1}}
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
end


-- Public functions.

function eatyguy.init()

  -- Set up the grid size and pseudorandom number generation.
  grid_w, grid_h = 39, 23
  math.randomseed(os.time())

  -- Build the maze.
  grid = {}
  for x = 1, grid_w do grid[x] = {} end
  drill_path_from(1, 1)

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
    io.write('\r\n')                 -- Move cursor to next row.
  end
end

function eatyguy.loop(state)
  update(state)
  draw(state.clock)
end

return eatyguy
