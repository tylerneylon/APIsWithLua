local curses = require 'curses'
local posix  = require 'posix'


-- Parameters.

do_use_curses = true
maze_color    = nil

-- maze_grid[x][y] = set of 'x,y' pairs that are adjacent without a wall.
maze_grid = nil

local function set_color(c)
  if not do_use_curses then return end
  stdscr:attron(curses.color_pair(c))
end

local function draw_point(x, y, color, point_char)
  if not do_use_curses then
    print('draw_point(' .. x .. ', ' .. y ..')')
    return
  end
  point_char = point_char or ' '  -- Space is the default point_char.
  if color then set_color(color) end
  for i = 0, 1 do
    stdscr:mvaddstr(y, 2 * x + i, point_char)
  end
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
  if do_use_curses then stdscr:erase() end

  local scr_width = curses.cols() - 1  -- Avoid the rightmost column.
  local w = math.floor(scr_width / 2)
  if not do_use_curses then w = 116 end

  -- Make sure w is odd, sliding down one number if needed.
  w = math.ceil(w / 2) * 2 - 1
  local h = 41

  -- Check that w, h are odd.
  assert((w - 1) / 2 == math.floor(w / 2))
  assert((h - 1) / 2 == math.floor(h / 2))

  if maze_grid == nil then
    build_maze((w - 1) / 2, (h - 1) / 2)
  end

  draw_border(w, h)
  draw_maze()

  --for x = 1, scr_width do
  --  draw_point(x, 1, colors.blue)
  --end

  -- TODO HERE
  if do_use_curses then stdscr:refresh() end  -- TODO needed?
end

function init()

  colors = { white   = 1, blue = 2, cyan   = 3, green = 4,
             magenta = 5, red  = 6, yellow = 7, black = 8 }

  if not do_use_curses then return end

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

end

init()
maze_color = colors.blue
do_repeat = true
while do_repeat do
  scr_width = curses.cols()
  draw()
  do_repeat = do_use_curses
end

if do_use_curses then curses.endwin() end
print('saw scr_width = ' .. scr_width)
