-- eatyguy.lua
--
-- Script for a simple terminal-based game.
--

local eatyguy = {}


-- Parameters.

local do_shorten_levels   = true
local percent_extra_paths = 30


-- Internal globals.

local cols  = nil
local lines = nil

-- Cached term strings.

local term_clear_str = nil
local term_home_str

-- maze_grid[x][y] = set of 'x,y' pairs that are adjacent without a wall.
local maze_grid  = nil
local maze_color = 4
local bg_color   = 0  -- Black by default.
local fg_color   = 7  -- White by default.
local grid       = nil  -- grid[x][y] = what's at that spot; falsy == wall.
local grid_w, grid_h = nil, nil


local player = {pos      = {1, 1},
                dir      = {1, 0},
                next_dir = {1, 0},
                lives    = 3,
                color    = 'player'}

local baddies    = {}  -- This will be set up in init.
local game_state = 'playing'
local score      = 0
local level      = 1
local dots_left  = 0


local function str_from_cmd(cmd)
  local p = io.popen(cmd)
  local s = p:read()
  p:close()
  return s
end

-- TODO Consolidate tput calls into this.

local term_strs = {}  -- Maps cmd -> str.

local function cached_cmd(cmd)
  if not term_strs[cmd] then
    term_strs[cmd] = str_from_cmd(cmd)
  end
  io.write(term_strs[cmd])
end

local function to_xy(x, y)
  cached_cmd('tput cup ' .. y .. ' ' .. (x + 2))
end


local num_calls_left = 100

-- This edits maze_grid by adding adjacent grid spaces, effectively drilling
-- through walls. It's like a depth-first search except that we make some random
-- choices along the way.
local function drill_from(x, y, already_visited)

  if already_visited == nil then
    -- This is a map ('x,y' -> true) for coordintes that we've already visited.
    already_visited = {}
  end

  local function consider_nbor(nx, ny, nbors)
    if nx > 0 and nx <= w and
       ny > 0 and ny <= h then
      xy_str = ('%d,%d'):format(nx, ny)
      if not already_visited[xy_str] then
        table.insert(nbors, xy_str)
      end
    end
  end

  num_calls_left = num_calls_left - 1

  -- if num_calls_left <= 0 then return end

  local xy_str = ('%d,%d'):format(x, y)
  already_visited[xy_str] = true

  x = tonumber(x)
  y = tonumber(y)

  w = #maze_grid
  h = #maze_grid[1]

  -- 1. Find available neighbors.

  local nbors = {}  -- This will be a list of 'x,y' strings.

  for dx = -1, 1, 2 do
    local nx, ny = x + dx, y
    consider_nbor(nx, ny, nbors)
  end

  for dy = -1, 1, 2 do
    local nx, ny = x, y + dy
    consider_nbor(nx, ny, nbors)
  end

  --io.stderr:write(('#nbors = %d\n'):format(#nbors))

  -- 2. If we don't have nbors, we're at an endpoint in the depth-first srch.

  if #nbors == 0 then return end

  -- 3. If we have nbors, choose a random one and drill from there.

  -- TEMP
  for i, nbor in pairs(nbors) do
    if already_visited[nbor] then table.remove(nbors, i) end
    --if math.random(1, 2) == 1 then table.remove(nbors, i) end
  end

  while #nbors > 0 do
    local i = math.random(1, #nbors)
    local nbor = nbors[i]
    local nx, ny = nbor:match('(%d+),(%d+)')
    nx, ny = tonumber(nx), tonumber(ny)
    table.insert(maze_grid[x][y], nbor)
    table.insert(maze_grid[nx][ny], xy_str)
    drill_from(nx, ny, already_visited)
    table.remove(nbors, i)

    -- Filter out visited nbors. This method lets some already visited nbors
    -- through the filter, but fewer than method 2.
    local i = 0
    while i <= #nbors do
      local is_extra_path_ok = (math.random(1, 100) >= percent_extra_paths)
      if already_visited[nbors[i]] and is_extra_path_ok then
        table.remove(nbors, i)
      else
        i = i + 1
      end
    end
  end

  return 'done'
end

local function build_maze(w, h)

  -- Initialize maze_grid.
  maze_grid = {}
  for x = 1, w do
    maze_grid[x] = {}
    for y = 1, h do
      maze_grid[x][y] = {}
    end
  end

  -- Drill out paths to make the maze.
  local x, y = math.random(1, w), math.random(1, h)
  drill_from(x, y)
end

-- The input x, y is in the coordinates of maze_grid.
-- The dx, dy values are expected to both be in {0, 1}.
local function get_wall_pos(x, y, dx, dy)
  x = 2 * x + dx - 1
  y = 2 * y + dy - 1
  return x, y
end

local function setup_grid()

  -- Set up an empty grid.
  grid = {}
  for x = 1, grid_w do
    grid[x] = {}
  end
  dots_left = 0

  -- Convert maze_grid to grid.
  maze_w = #maze_grid
  maze_h = #maze_grid[1]

  for x = 1, maze_w do
    for y = 1, maze_h do

      -- Determine nbor directions which have a wall.
      local nbors = {[('%d,%d'):format(x + 1, y)]     = 'wall',
                     [('%d,%d'):format(x + 1, y + 1)] = 'wall',
                     [('%d,%d'):format(x,     y + 1)] = 'wall'}
      for _, other in pairs(maze_grid[x][y]) do
        for nbor in pairs(nbors) do
          if other == nbor then
            nbors[nbor] = 'open'
          end
        end
      end

      -- Move data into grid.
      for nbor, state in pairs(nbors) do
        -- Parse out the x, y delta.
        local nx, ny = nbor:match('(%d+),(%d+)')
        local dx, dy = nx - x, ny - y
        local px, py = get_wall_pos(x, y, dx, dy)
        grid[px][py] = false
        if state == 'open' then
          grid[px][py] = '.'
          dots_left = dots_left + 1
        end
      end
      local px, py = get_wall_pos(x, y, 0, 0)
      grid[px][py] = '.'
      dots_left = dots_left + 1
    end
  end

  if do_shorten_levels then
    dots_left = 20
  end
end

local function ensure_color(sprite)
  -- Missing entries mean we don't care.
  local fg = {level = 6, dots = 7, player = 0}
  local bg = {level = 0, dots = 0, player = 3}
  local fg_val, bg_val

  -- Extract {fg,bg}_val from the sprite value.
  if type(sprite) == 'number' then
    fg_val, bg_val = 0, sprite
  else
    for name, val in pairs(bg) do
      if name == sprite then
        fg_val, bg_val = fg[name], val
      end
    end
  end

  -- Set colors, minimizing work.
  if bg_color ~= bg_val then
    cached_cmd('tput setab ' .. bg_val)
    bg_color = bg_val
  end
  if fg_val and fg_color ~= fg_val then
    cached_cmd('tput setaf ' .. fg_val)
    fg_color = fg_val
  end
end

local function erase_pos(p)
  local ch = grid[p[1]][p[2]]
  -- A former non-wall may change to a wall when we set up a new level.
  -- In that case, there's no need to erase the old position.
  if not ch then return end
  ensure_color('dots')
  local x = 2 * p[1]
  local y =     p[2]
  to_xy(x, y)
  io.write(grid[p[1]][p[2]] .. ' ')
end

local function reset_positions(do_erase)
  player.pos = {1, 1}
  for _, baddy in pairs(baddies) do
    if do_erase then erase_pos(baddy.pos) end
    baddy.pos = baddy.home
  end
end

local function draw_maze()
  cached_cmd('tput home')
  for y = 0, grid_h - 1 do
    ensure_color('dots')
    io.write('  ')
    for x = 0, grid_w - 1 do
      if grid[x] and grid[x][y] then
        -- Draw dots.
        ensure_color('dots')
        io.write('. ')
      else
        -- Draw a wall.
        ensure_color(maze_color)
        io.write('  ')
      end
    end
    io.write('\r\n')
  end
  ensure_color('level')
  io.write(('Level: %4d\r\n'):format(level))
  io.write(('Score: %4d\r\n'):format(score))
end

-- TODO consolidate
local function setup_next_level()
  level = level + 1
  score = score + 1000
  local maze_colors = {2, 4, 5, 6, 1}
  maze_color = maze_colors[(level % #maze_colors) + 1]
  build_maze((grid_w - 1) / 2, (grid_h - 1) / 2)
  setup_grid()
  reset_positions()
  draw_maze()
end

--[[
local function maze_pt_from_grid_pt(x, y)
  -- Map 1 -> 1; 3 -> 2, etc.
  x = (x - 1)
end
--]]

-- Set ch.dir to an open direction, and move one step in that direction.
local function set_rand_dir(ch)
  -- Find available directions.
  local dirs = {}
  local deltas = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
  local p = ch.pos
  for _, d in pairs(deltas) do
    local gx, gy = p[1] + d[1], p[2] + d[2]
    if grid[gx] and grid[gx][gy] then
      table.insert(dirs, d)
    end
  end

  -- Choose a random direction and go that way.
  local dir = math.random(#dirs)
  ch.dir = dirs[dir]
  ch.pos = {p[1] + ch.dir[1], p[2] + ch.dir[2]}

  -- Set next_dir to a random delta.
  ch.next_dir = deltas[math.random(4)]
end

-- Check if a character can move in a given direction.
-- Return can_move, new_pos.
local function can_move_in_dir(character, dir)
  local p = character.pos
  local gx, gy = p[1] + dir[1], p[2] + dir[2]
  return (grid[gx] and grid[gx][gy]), {gx, gy}
end

local function eat_dot(pos)
  score = score + 10
  dots_left = dots_left - 1
  -- TODO consolidate
  to_xy(0, #grid[1] + 2)
  ensure_color('level')
  io.write(('Score: %4d\r\n'):format(score))
  grid[pos[1]][pos[2]] = ' '
  if dots_left == 0 then
    setup_next_level()
  end
end

local function update_player(elapsed, key, do_move)

  local p = player.pos
  if grid[p[1]][p[2]] == '.' then eat_dot(p) end

  -- Update our direction if we have a known key.
  local dir_by_key = {
    [68] = {-1,  0},
    [65] = { 0, -1},
    [66] = { 0,  1},
    [67] = { 1,  0}
  }
  if dir_by_key[key] then
    player.next_dir = dir_by_key[key]
  end

  -- Change direction if we can; otherwise the next_dir will take effect if we
  -- hit a corner where we can turn in that direction.
  if can_move_in_dir(player, player.next_dir) then
    player.dir = player.next_dir
  end

  -- Don't move if it's not a move timestamp.
  if not do_move then return end

  -- Move in player.dir if possible.
  local can_move, new_pos = can_move_in_dir(player, player.dir)
  if can_move then
    player.old_pos = player.pos  -- Save the old position.
    player.pos = new_pos
  end

  do return end

  -- Find open spaces.
  local spaces = {}
  local deltas = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
  local p = player.pos
  for _, d in pairs(deltas) do
    local gx, gy = p[1] + d[1], p[2] + d[2]
    if grid[gx] and grid[gx][gy] then
      table.insert(spaces, {gx, gy})
    end
  end

  -- Choose a random direction and go that way.
  local dir = math.random(#spaces)
  player.pos = spaces[dir]
end

local function set_random_next_dir(character)
  local deltas = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
  character.next_dir = deltas[math.random(4)]
end

local function update_baddy(elapsed, baddy, do_move)
  if not do_move then return end
  baddy.old_pos = baddy.pos
  if can_move_in_dir(baddy, baddy.next_dir) then
    baddy.dir = baddy.next_dir
    set_random_next_dir(baddy)
  end
  local can_move, new_pos = can_move_in_dir(baddy, baddy.dir)
  if can_move then
    baddy.pos = new_pos
  else
    set_rand_dir(baddy)
  end
end

local function pos_for_player_life(n)
  return {#grid - 2 * n, #grid[1] + 1}
end

local function draw_character(c)
  ensure_color(c.color)
  local x = 2 * c.pos[1]
  local y =     c.pos[2]
  to_xy(x, y)
  io.write(c.draw)

  -- Erase old character if appropriate.
  if c.old_pos then
    erase_pos(c.old_pos)
    c.old_pos = nil
  end
end

local function check_for_death()
  for _, baddy in pairs(baddies) do
    if player.pos[1] == baddy.pos[1] and
       player.pos[2] == baddy.pos[2] then
      player.lives = player.lives - 1
      player.color = 'dots'
      player.pos = pos_for_player_life(player.lives)
      player.draw = '  '
      draw_character(player)
      if player.lives == 0 then
        game_state = 'Game over!'
      end
      player.color = 'player'
      reset_positions(true)  -- true --> do_erase
      return true  -- Player did die.
    end
  end
  return false  -- Player survived .. for now.
end

local next_move_time = 0
local move_delta     = 0.2  -- seconds

local function update(elapsed, key)
  local do_move = (elapsed >= next_move_time)
  if do_move then
    next_move_time = next_move_time + move_delta
  end
  update_player(elapsed, key, do_move)
  check_for_death()
  for _, baddy in pairs(baddies) do
    update_baddy(elapsed, baddy, do_move)
  end
  check_for_death()  -- Check if a baddy hit the player.
end

local function draw_player(elapsed)

  -- Set up player-drawing data.
  local open, close = "'<", "'-"
  if     player.dir[1] ==  1 then
    open, close = "'<", "'-"
  elseif player.dir[1] == -1 then
    open, close = ">'", "-'"
  elseif player.dir[2] ==  1 then
    open, close = "^'", "|'"
  elseif player.dir[2] == -1 then
    open, close = "v.", "'."
  end

  -- Choose the sprite.
  local anim_timestep = 0.2
  if math.floor(elapsed / anim_timestep) % 2 == 0 then
    player.draw = open
  else
    player.draw = close
  end

  draw_character(player)
end

local function draw(elapsed)
  io.write(term_home_str)

  --draw_maze()
  draw_player(elapsed)
  for _, baddy in pairs(baddies) do
    draw_character(baddy)
  end

  -- Draw lives remaining.
  local pl_pos = player.pos
  player.draw = "'<"
  for i = 1, player.lives - 1 do
    player.pos = pos_for_player_life(i)
    draw_character(player)
  end
  player.pos = pl_pos

  io.flush() -- TODO needed?
end

local function num_from_cmd(cmd)
  p = io.popen(cmd)
  n = tonumber(p:read())
  p:close()
  return n
end

function eatyguy.init()

  os.execute('tput reset')
  os.execute('tput civis')

  cols  = num_from_cmd('tput cols')
  lines = num_from_cmd('tput lines')

  grid_w = math.floor((cols - 3) / 2)          -- Grid cells are 2 chars.
  grid_w = math.ceil(grid_w / 2) * 2 - 1       -- Ensure grid_w is odd.
  grid_h = math.ceil((lines - 3) / 2) * 2 - 1  -- Ensure grid_h is odd.

  -- Check that grid_w, grid_h are odd.
  assert((grid_w - 1) / 2 == math.floor(grid_w / 2))
  assert((grid_h - 1) / 2 == math.floor(grid_h / 2))

  build_maze((grid_w - 1) / 2, (grid_h - 1) / 2)
  setup_grid()

  term_clear_str = str_from_cmd('tput clear')
  term_home_str = str_from_cmd('tput home')
  io.write(term_clear_str)

  math.randomseed(os.time())

  -- Set up the baddies.
  baddies = { {color = 1, draw = 'oo', pos = {1, 1} },
              {color = 2, draw = '@@', pos = {1, 0} },
              {color = 5, draw = '^^', pos = {0, 1} }}
  for _, baddy in pairs(baddies) do
    baddy.dir      = {-1, 0}
    baddy.next_dir = {-1, 0}
    baddy.pos = {(#grid - 3) * baddy.pos[1] + 1,
                 (#grid[1] - 2) * baddy.pos[2] + 1}
    baddy.home = baddy.pos
  end

  colors = { white   = 1, blue = 2, cyan   = 3, green = 4,
             magenta = 5, red  = 6, yellow = 7, black = 8 }

  draw_maze()
end

function eatyguy.loop(elapsed, key)
  update(elapsed, key)
  draw(elapsed)
  return game_state, score
end

return eatyguy
