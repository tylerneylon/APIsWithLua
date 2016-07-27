-- drawmaze2.lua
--
-- Precursor to a game to be used to show off some example code.
--


-- Parameters.

do_use_curses       = true
maze_color          = nil
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
maze_grid = nil

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
      print('------')
      print(('connecting %s and %s'):format(xy_str, nbor))
      av_self = already_visited[xy_str]
      print(('already_visited[%s] = %s'):format(xy_str, av_self and 'T' or 'F'))
      av_nbor = already_visited[nbor]
      print(('already_visited[%s] = %s'):format(nbor, av_nbor and 'T' or 'F'))
      print('')
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

  io.stderr:write('maze_grid initialized\n\n')

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

local function draw_maze()
  w = #maze_grid
  h = #maze_grid[1]

  for x = 1, w do
    for y = 1, h do

      -- Determine nbor directions which have a wall.
      local nbors = {('%d,%d'):format(x + 1, y),
                     ('%d,%d'):format(x + 1, y + 1),
                     ('%d,%d'):format(x, y + 1)}
      for _, other in pairs(maze_grid[x][y]) do
        for i, nbor in pairs(nbors) do
          if other == nbor then
            table.remove(nbors, i)  -- Remove nbor; no wall that way.
          end
        end
      end

      -- Draw remaining nbor directions with a wall.
      for _, nbor in pairs(nbors) do
        -- Parse out the x, y delta.
        local nx, ny = nbor:match('(%d+),(%d+)')
        local dx, dy = nx - x, ny - y
        local px, py = get_wall_pos(x, y, dx, dy)
        draw_point(px, py, maze_color)
      end
    end
  end
end

function draw_border(w, h)
  local c = maze_color
  if not do_use_curses then print('w = ' .. w) end
  local k = 2
  --for x = 0, w - k, k do
  for x = 0, w - 1, w - 1 do
    --print('math.floor(w - k / 2) = ' .. math.floor(w - k / 2))
    --print('x = ' .. x)
    for y = 0, h - 1 do
      draw_point(x, y, c)
    end
  end
  for y = 0, h - 1, h - 1 do
    for x = 0, w - 1 do
      draw_point(x, y, c)
    end
  end
end

function draw()
  --if do_use_curses then stdscr:erase() end
  if do_use_curses then io.write(term_home_str) end

  --local scr_width = curses.cols() - 1  -- Avoid the rightmost column.
  local scr_width = cols - 1  -- Avoid the rightmost column.
  local w = math.floor(scr_width / 2)
  if not do_use_curses then w = 116 end

  -- Make sure w is odd, sliding down one number if needed.
  w = math.ceil(w / 2) * 2 - 1

  -- TEMP
  --w = 7
  local h = 31

  -- Check that w, h are odd.
  assert((w - 1) / 2 == math.floor(w / 2))
  assert((h - 1) / 2 == math.floor(h / 2))

  if maze_grid == nil then
    build_maze((w - 1) / 2, (h - 1) / 2)
  end

  draw_border(w, h)
  draw_maze()

  if do_animate and not is_animate_done then
    status = drill(1, 1)
    os.execute('sleep 0.01')
    if status == 'done' then is_animate_done = true end
  end

  --for x = 1, scr_width do
  --  draw_point(x, 1, colors.blue)
  --end
  
  -- Below is an attempt to draw a character, but it wasn't working for me.
  --[[
  --draw_point(1, 1, colors.yellow, '*')
  if do_use_curses then
    local c = colors.red
    stdscr:attron(curses.color_pair(c))
    local x, y = 1, 1
    stdscr:mvaddstr(y, 2 * x + 0, '>')
    stdscr:mvaddstr(y, 2 * x + 1, '-')
  end
  --]]

  -- TODO HERE
  --if do_use_curses then stdscr:refresh() end  -- TODO needed?
  if do_use_curses then io.flush() end  -- TODO needed?
end

local function num_from_cmd(cmd)
  p = io.popen(cmd)
  n = tonumber(p:read())
  p:close()
  return n
end

function init()

  cols  = num_from_cmd('tput cols')
  lines = num_from_cmd('tput lines')

  term_clear_str = str_from_cmd('tput clear')
  term_home_str = str_from_cmd('tput home')
  io.write(term_clear_str)

  math.randomseed(os.time())

  io.stderr:write('init() called\n\n')

  colors = { white   = 1, blue = 2, cyan   = 3, green = 4,
             magenta = 5, red  = 6, yellow = 7, black = 8 }

  if not do_use_curses then return end

  --[[
  -- Start up curses.
  curses.initscr()    -- Initialize the curses library and the terminal screen.
  curses.cbreak()     -- Turn off input line buffering.
  curses.echo(false)  -- Don't print out characters as the user types them.
  curses.nl(false)    -- Turn off special-case return/newline handling.
  curses.curs_set(0)  -- Hide the cursor.

  -- Set up colors.
  curses.start_color()
  if not curses.has_colors() then
    curses.endwin()
    print('Bummer! Looks like your terminal doesn\'t support colors :\'(')
    os.exit(1)
  end
  for k, v in pairs(colors) do
    curses_color = curses['COLOR_' .. k:upper()]
    curses.init_pair(v, curses_color, curses_color)
  end
  colors.text, colors.over = 9, 10
  curses.init_pair(colors.text, curses.COLOR_WHITE, curses.COLOR_BLACK)
  curses.init_pair(colors.over, curses.COLOR_RED,   curses.COLOR_BLACK)

  -- Set up our standard screen.
  stdscr = curses.stdscr()
  stdscr:nodelay(true)  -- Make getch nonblocking.
  stdscr:keypad()       -- Correctly catch arrow key presses.
  --]]

end

io.stderr:write('calling init()\n\n')
init()
maze_color = 1
do_repeat = true

io.stderr:write('maze_grid = ' .. tostring(maze_grid) .. '\n\n')

if do_animate then
  drill = coroutine.wrap(drill_from)
else
  drill = drill_from
end

while do_repeat do
  --scr_width = curses.cols()
  draw()
  do_repeat = do_use_curses
end

--if do_use_curses then curses.endwin() end
print('saw scr_width = ' .. scr_width)
