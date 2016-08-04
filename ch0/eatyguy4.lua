-- eatyguy.lua

local eatyguy = {}

-- Parameters.

local percent_extra_paths = 15
local grid                = nil       -- grid[x][y] = 'open', or falsy = a wall.
local grid_w, grid_h      = nil, nil

-- Internal functions.

local function is_in_bounds(x, y)
  return (1 <= x and x <= grid_w and
          1 <= y and y <= grid_h)
end

local function get_nbor_dirs(x, y, perc_extra)
  perc_extra = perc_extra or 0  -- The percent chance of including extra nbors.
  local nbor_dirs = {}
  local all_dirs = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
  for _, dir in pairs(all_dirs) do
    local nx, ny = x + 2 * dir[1], y + 2 * dir[2]
    local is_extra_ok = (math.random(100) <= perc_extra)
    if is_in_bounds(nx, ny) and (not grid[nx][ny] or is_extra_ok) then
      table.insert(nbor_dirs, dir)
    end
  end
  return nbor_dirs
end

local iters_left = 200

local function drill_path_from(x, y)
  iters_left = iters_left - 1
  if iters_left <= 0 then return end
  grid[x][y] = 'open'
  local nbor_dirs = get_nbor_dirs(x, y)
  while #nbor_dirs > 0 do
    local dir = table.remove(nbor_dirs, math.random(#nbor_dirs))
    grid[x + dir[1]][y + dir[2]] = 'open'
    drill_path_from(x + 2 * dir[1], y + 2 * dir[2])
    if iters_left <= 0 then return end
    nbor_dirs = get_nbor_dirs(x, y, percent_extra_paths)
  end
end

-- Public functions.

function eatyguy.init(il)

  iters_left = il

  grid_w, grid_h = 65, 41
  --math.randomseed(os.time()) -- XXX
  math.randomseed(1)

  -- Build the maze.
  grid = {}
  for x = 1, grid_w do grid[x] = {} end
  drill_path_from(1, 1)

  -- Draw the maze.
  for y = 0, grid_h + 1 do
    for x = 0, grid_w + 1 do
      -- The next line is essentially: chars = (grid[x][y] ? '  ' : '##').
      local chars = (grid[x] and grid[x][y]) and '  ' or '##'
      io.write(chars)
    end
    io.write('\n')  -- Move cursor to next row.
  end
end

return eatyguy
