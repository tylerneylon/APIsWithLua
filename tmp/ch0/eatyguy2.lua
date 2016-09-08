-- eatyguy.lua

local eatyguy = {}

-- Parameters.

local percent_extra_paths = 30
local grid                = nil       -- grid[x][y] = 'open', or falsy = a wall.
local grid_w, grid_h      = nil, nil

-- Internal functions.

local function should_drill(x, y)
  if x < 1 or x > grid_w then return false end
  if y < 1 or y > grid_h then return false end
  return not grid[x][y]  -- Spaces are valid for search only if not yet seen.
end

local function drill_path_from(x, y)

  -- Mark the path as open; this means it's been seen by the depth-first search.
  grid[x][y] = 'open'

  -- Find nbor directions which are in bounds and not yet seen.
  local nbor_dirs = {}
  for _, d in pairs({{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) do
    if should_drill(x + 2 * d[1], y + 2 * d[2]) then
      table.insert(nbor_dirs, d)
    end
  end

  -- TODO NEXT The chunk below is a bit dense. Try to improve readability.

  -- Recursively visit nbor_dirs, dropping newly seen directions as we go.
  while #nbor_dirs > 0 do
    local d = table.remove(nbor_dirs, math.random(#nbor_dirs))
    grid[x + d[1]][y + d[2]] = 'open'
    drill_path_from(x + 2 * d[1], y + 2 * d[2])
    for i = #nbor_dirs, 1, -1 do
      local nx, ny = x + 2 * nbor_dirs[i][1], y + 2 * nbor_dirs[i][2]
      local is_extra_path_ok = (math.random(1, 100) <= percent_extra_paths)
      if grid[nx][ny] and not is_extra_path_ok then
        table.remove(nbor_dirs, i)
      end
    end
  end
end

-- Public functions.

function eatyguy.init()
  grid_w, grid_h = 65, 41
  math.randomseed(os.time())

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
