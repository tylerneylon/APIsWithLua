-- eatyguy.lua
--
-- Script for a simple terminal-based game.
--

local eatyguy = {}


-- Parameters.

local percent_extra_paths = 30


-- Internal globals.

local cols  = nil
local lines = nil

local maze_color = 4  -- Blue by default.
local bg_color   = 0  -- Black by default.
local fg_color   = 7  -- White by default.
local grid       = nil  -- grid[x][y] = what's at that spot; falsy == wall.
local grid_w, grid_h = nil, nil
local dots_left  = 0


local function str_from_cmd(cmd)
  local p = io.popen(cmd)
  local s = p:read()
  p:close()
  return s
end

local term_strs = {}  -- Maps cmd -> str.

local function cached_cmd(cmd)
  if not term_strs[cmd] then
    term_strs[cmd] = str_from_cmd(cmd)
  end
  io.write(term_strs[cmd])
end

local function drill_from(x, y, already_visited)

  -- 1. Set up supporting functions and data.
  local function xy_str(x, y)
    return ('%d,%d'):format(x, y)
  end
  if already_visited == nil then
    -- This is a map ('x,y' -> true) for coordinates that we've already visited.
    already_visited = {}
  end

  -- 2. Register this point as visited and not a wall.
  if not grid[x][y] then
    grid[x][y] = '.'
    dots_left = dots_left + 1
  end
  already_visited[xy_str(x, y)] = true

  -- 3. Find available neighbors.
  local nbors = {}
  local deltas = {{-2, 0}, {2, 0}, {0, -2}, {0, 2}}
  for _, d in pairs(deltas) do
    local nx, ny = x + d[1], y + d[2]
    if nx > 0 and nx <= grid_w and
       ny > 0 and ny <= grid_h and
       not already_visited[xy_str(nx, ny)] then
        table.insert(nbors, {nx, ny})
    end
  end

  -- 4. If we don't have nbors, we're at an endpoint in the depth-first srch.
  if #nbors == 0 then return end

  -- 5. If we have nbors, choose a random one and drill from there.
  while #nbors > 0 do
    local i      = math.random(1, #nbors)
    local nx, ny = nbors[i][1], nbors[i][2]
    local dx, dy = (nx - x) / 2, (ny - y) / 2
    grid[x + dx][y + dy] = '.'  -- This will always be a wall until now.
    dots_left = dots_left + 1
    drill_from(nx, ny, already_visited)
    table.remove(nbors, i)

    -- Filter out visited nbors. This method lets some already visited nbors
    -- through the filter to add more paths to the maze.
    local i = 1
    while i <= #nbors do
      local is_extra_path_ok = (math.random(1, 100) <= percent_extra_paths)
      local nx, ny = nbors[i][1], nbors[i][2]
      if already_visited[xy_str(nx, ny)] and not is_extra_path_ok then
        table.remove(nbors, i)
      else
        i = i + 1
      end
    end
  end
end

local function build_maze()

  -- Set up an empty grid.
  grid = {}
  for x = 1, grid_w do
    grid[x] = {}
  end
  dots_left = 0

  -- Drill out paths to make the maze.
  local x = math.random((grid_w + 1) / 2) * 2 - 1
  local y = math.random((grid_h + 1) / 2) * 2 - 1
  drill_from(x, y)
end

local function set_color(sprite)
  local fg = {dots = 7}
  local bg = {dots = 0}
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

  cached_cmd('tput setab ' .. bg_val)
  cached_cmd('tput setaf ' .. fg_val)
end

local function draw_maze()
  cached_cmd('tput home')
  for y = 0, grid_h + 1 do
    set_color('dots')
    io.write('  ')
    for x = 0, grid_w + 1 do
      if grid[x] and grid[x][y] then
        -- Draw dots.
        set_color('dots')
        io.write('. ')
      else
        -- Draw a wall.
        set_color(maze_color)
        io.write('  ')
      end
    end
    io.write('\r\n')  -- Move cursor to next row.
  end
end

local function setup_next_level()
  maze_color = 4  -- Blue!
  build_maze()
  draw_maze()
end

function eatyguy.init()

  cached_cmd('tput reset')
  cached_cmd('tput civis')

  cols  = tonumber(str_from_cmd('tput cols'))
  lines = tonumber(str_from_cmd('tput lines'))

  grid_w = math.floor((cols - 1) / 2)          -- Grid cells are 2 chars.
  grid_h = lines - 1                           -- Avoid the last col/line.

  grid_w = grid_w - 3    -- Allow room for the border + left margin.
  grid_h = grid_h - 4    -- Allow room for the border + score / level.

  grid_w = math.ceil(grid_w / 2) * 2 - 1       -- Ensure both are odd.
  grid_h = math.ceil(grid_h / 2) * 2 - 1

  math.randomseed(os.time())
  setup_next_level()
end

return eatyguy
