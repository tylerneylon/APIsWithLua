-- eatyguy.lua
--
-- Script for a simple terminal-based game.
--

local eatyguy = {}


-- Parameters.

do_use_curses       = true
do_animate          = false
is_animate_done     = false
percent_extra_paths = 30


-- Internal globals.

drill = nil  -- TEMP TODO delete

cols  = nil
lines = nil


-- Cached term strings.

local term_clear_str = nil
local term_home_str


-- maze_grid[x][y] = set of 'x,y' pairs that are adjacent without a wall.
local maze_grid = nil
local grid      = nil  -- grid[x][y] = what's at that spot; falsy == wall.
local grid_w, grid_h = nil, nil
local bg_color = 0  -- Black by default.  -- TODO consider if these are good
local fg_color = 7  -- White by default.


local player = {pos      = {1, 1},
                dir      = {1, 0},
                next_dir = {1, 0},
                lives    = 3}
local frame_num = 0

local baddies = {}  -- This will be set up in init.
local game_state = 'playing'  -- Or 'game over'.


local function str_from_cmd(cmd)
  local p = io.popen(cmd)
  local s = p:read()
  p:close()
  return s
end

local term_color_strs = {}  -- [color_num] -> terminal string

local function set_color(c)
  if not do_use_curses then return end
  if term_color_strs[c] == nil then
    term_color_strs[c] = str_from_cmd('tput setab ' .. c)
  end
  io.write(term_color_strs[c])
  --stdscr:attron(curses.color_pair(c))
end

local term_cup_strs = {}  -- ['x,y'] -> terminal string

local function draw_char_at_pt(y, x, ch)
  local xy_str = ('%d,%d'):format(x, y)
  if term_cup_strs[xy_str] == nil then
    term_cup_strs[xy_str] = str_from_cmd('tput cup ' .. y .. ' ' .. x)
  end
  io.write(term_cup_strs[xy_str] .. ' ')
end

-- TODO Consolidate tput calls into this.

local term_strs = {}  -- Maps cmd -> str.

local function cached_cmd(cmd)
  if not term_strs[cmd] then
    term_strs[cmd] = str_from_cmd(cmd)
  end
  io.write(term_strs[cmd])
end

local function draw_point(x, y, color, point_char)
  if not do_use_curses then
    --print('draw_point(' .. x .. ', ' .. y ..')')
    return
  end
  point_char = point_char or ' '  -- Space is the default point_char.

  if color then set_color(color) end
  for i = 0, 1 do
    --stdscr:mvaddstr(y, 2 * x + i, point_char)
    draw_char_at_pt(y, 2 * x + i, point_char)
  end
end

-- This is a map ('x,y' -> true) for coordintes that we've already visited.
local already_visited = {}

local function consider_nbor(nx, ny, nbors)
  if nx > 0 and nx <= w and
     ny > 0 and ny <= h then
    xy_str = ('%d,%d'):format(nx, ny)
    if not already_visited[xy_str] then
      table.insert(nbors, xy_str)
    end
  end
end

local num_calls_left = 100

-- This edits maze_grid by adding adjacent grid spaces, effectively drilling
-- through walls. It's like a depth-first search except that we make some random
-- choices along the way.
local function drill_from(x, y)

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
    if not do_use_curses then
      --print('------')
      --print(('connecting %s and %s'):format(xy_str, nbor))
      av_self = already_visited[xy_str]
      --print(('already_visited[%s] = %s'):format(xy_str, av_self and 'T' or 'F'))
      av_nbor = already_visited[nbor]
      --print(('already_visited[%s] = %s'):format(nbor, av_nbor and 'T' or 'F'))
      --print('')
    end
    table.insert(maze_grid[x][y], nbor)
    table.insert(maze_grid[nx][ny], xy_str)
    if do_animate then coroutine.yield() end
    drill_from(nx, ny)
    table.remove(nbors, i)

    -- Method 1.
    -- Filter out visited nbors. This method works correctly.
    --[=[
    local i = 0
    while i <= #nbors do
      if already_visited[nbors[i]] then
        table.remove(nbors, i)
      else
        i = i + 1
      end
    end
    --]=]

    -- Method 2.
    -- Filter out visited nbors. This method lets some already visited nbors
    -- through the filter, which results in some holes in the walls.
    --[[
    for i, nbor in pairs(nbors) do
      if already_visited[nbor] then table.remove(nbors, i) end
    end
    --]]
    
    -- Method 3.
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

  -- io.stderr:write('maze_grid initialized\n\n')

  local x, y = math.random(1, w), math.random(1, h)

  if not do_animate then drill_from(x, y) end

  --maze_grid[1][1] = {'2,1', '1,2'}

  -- TODO build maze_grid
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
        if state == 'open' then grid[px][py] = '.' end
      end
      local px, py = get_wall_pos(x, y, 0, 0)
      grid[px][py] = '.'
    end
  end
end

local wcolor = 1

local function ensure_color(sprite)
  -- Missing entries mean we don't care.
  local fg = {dots = 7, player = 0}
  local bg = {dots = 0, wall = 4, player = 3}
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

local function update_player(elapsed, key, do_move)

  --cached_cmd('tput cup ' .. (lines - 1) .. ' 0')
  --io.write(('key = %d'):format(key))

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

local function check_for_death()
  for _, baddy in pairs(baddies) do
    if player.pos[1] == baddy.pos[1] and
       player.pos[2] == baddy.pos[2] then
      player.lives = player.lives - 1
      if player.lives == 0 then
        --os.execute('stty cooked')
        --os.execute('tput reset')
        --os.exit()
        game_state = 'game over'
      end
      player.pos = {1, 1}
    end
  end
end

local next_move_time = 0
local move_delta     = 0.2  -- seconds

local function update(elapsed, key)
  local do_move = (elapsed >= next_move_time)
  if do_move then
    next_move_time = next_move_time + move_delta
  end
  update_player(elapsed, key, do_move)
  check_for_death()  -- Check if the player hit a baddy.
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

  -- Draw the player.
  ensure_color('player')
  local x = 2 * player.pos[1]
  local y =     player.pos[2]
  cached_cmd('tput cup ' .. y .. ' ' .. x)
  local anim_timestep = 0.2
  if math.floor(elapsed / anim_timestep) % 2 == 0 then
  --if (math.floor(frame_num / 20)) % 2 == 0 then
    io.write(open)
  else
    io.write(close)
  end

  -- Erase old player if appropriate.
  if player.old_pos then
    ensure_color('dots')
    local x = 2 * player.old_pos[1]
    local y =     player.old_pos[2]
    cached_cmd('tput cup ' .. y .. ' ' .. x)
    io.write('. ')
    player.old_pos = nil
  end
end

-- TODO Try to consolidate with draw_player.
local function draw_baddy(baddy)

  -- Draw baddy.
  ensure_color(baddy.color)
  local x = 2 * baddy.pos[1]
  local y =     baddy.pos[2]
  cached_cmd('tput cup ' .. y .. ' ' .. x)
  io.write(baddy.draw)

  -- Erase old baddy if appropriate.
  if baddy.old_pos then
    ensure_color('dots')
    local x = 2 * baddy.old_pos[1]
    local y =     baddy.old_pos[2]
    cached_cmd('tput cup ' .. y .. ' ' .. x)
    io.write('. ')
    baddy.old_pos = nil
  end
end

local function draw_maze()
  -- XXX
  --wcolor = (wcolor + 1) % 256

  if math.random() < 0.1 then
    local delta = 1
    if math.random() < 0.5 then delta = -1 end
    wcolor = wcolor + delta
    if wcolor < 242 then wcolor = 242 end
    if wcolor > 255 then wcolor = 255 end
  end

  cached_cmd('tput home')
  for y = 0, grid_h - 1 do
    for x = 0, grid_w - 1 do
      if grid[x] and grid[x][y] then
        -- Draw dots.
        ensure_color('dots')
        io.write('. ')
      else
        -- Draw a wall.
        ensure_color('wall')
        io.write('  ')
      end
    end
    io.write('\r\n')
  end
end

local function draw(elapsed)
  --if do_use_curses then stdscr:erase() end
  if do_use_curses then io.write(term_home_str) end

  --draw_maze()
  draw_player(elapsed)
  for _, baddy in pairs(baddies) do
    draw_baddy(baddy)
  end

  if do_animate and not is_animate_done then
    status = drill(1, 1)
    os.execute('sleep 0.01')
    if status == 'done' then is_animate_done = true end
  end

  if do_use_curses then io.flush() end  -- TODO needed?
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

  -- XXX
  grid_w = math.floor((cols - 5) / 2)          -- Grid cells are 2 chars.
  grid_w = math.ceil(grid_w / 2) * 2 - 1       -- Ensure grid_w is odd.
  grid_h = math.ceil((lines - 5) / 2) * 2 - 1  -- Ensure grid_h is odd.

  -- Check that grid_w, grid_h are odd.
  assert((grid_w - 1) / 2 == math.floor(grid_w / 2))
  assert((grid_h - 1) / 2 == math.floor(grid_h / 2))

  build_maze((grid_w - 1) / 2, (grid_h - 1) / 2)
  setup_grid()

  term_clear_str = str_from_cmd('tput clear')
  term_home_str = str_from_cmd('tput home')
  io.write(term_clear_str)

  -- XXX
  --math.randomseed(os.time())
  math.randomseed(10)

  -- io.stderr:write('init() called\n\n')

  -- Set up the baddies.
  baddies = { {color = 1, draw = 'oo', pos = {1, 1} },
              {color = 2, draw = '@@', pos = {1, 0} },
              {color = 5, draw = '^^', pos = {0, 1} }}
  for _, baddy in pairs(baddies) do
    baddy.dir      = {-1, 0}
    baddy.next_dir = {-1, 0}
    baddy.pos = {(#grid - 3) * baddy.pos[1] + 1,
                 (#grid[1] - 2) * baddy.pos[2] + 1}
  end

  colors = { white   = 1, blue = 2, cyan   = 3, green = 4,
             magenta = 5, red  = 6, yellow = 7, black = 8 }

  draw_maze()

  if not do_use_curses then return end
end

function eatyguy.loop(elapsed, key)
  update(elapsed, key)
  draw(elapsed)
  frame_num = frame_num + 1
  return game_state  -- Either 'playing' or 'game over'.
end

return eatyguy
