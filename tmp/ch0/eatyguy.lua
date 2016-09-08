-- eatyguy.lua

local eatyguy = {}

-- Parameters.

local percent_extra_paths = 30
local grid       = nil  -- grid[x][y] = what's at that spot; falsy == wall.
local grid_w, grid_h = nil, nil

-- Internal functions.

local function drill_from(x, y, already_visited)
  -- 1. Set up.
  local function xy_str(x, y)       -- Useful for making table keys.
    return ('%d,%d'):format(x, y)
  end
  if already_visited == nil then    -- already_visited is nil for the root call.
    already_visited = {}
  end
  grid[x][y] = true                     -- Mark x, y as an open space.
  already_visited[xy_str(x, y)] = true  -- Mark that we've been here.

  -- 2. Find available neighbors.
  local nbor_dirs = {}
  for _, d in pairs({{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) do
    local nx, ny = x + 2 * d[1], y + 2 * d[2]
    if nx > 0 and nx <= grid_w and
       ny > 0 and ny <= grid_h and
       not already_visited[xy_str(nx, ny)] then
        table.insert(nbor_dirs, d)
    end
  end

  -- 3. If we have no nbor_dirs, we're at an endpoint in the depth-first srch.
  if #nbor_dirs == 0 then return end

  -- 4. If we have nbor_dirs, choose a random one and drill from there.
  while #nbor_dirs > 0 do
    local i = math.random(#nbor_dirs)
    local d = nbor_dirs[i]
    grid[x + d[1]][y + d[2]] = true  -- Set the adjacent grid cell as open.
    drill_from(x + 2 * d[1], y + 2 * d[2], already_visited)
    table.remove(nbor_dirs, i)

    -- Filter out visited nbors. This method lets some already visited nbors
    -- through the filter to add more paths to the maze.
    for i = #nbor_dirs, 1, -1 do
      local is_extra_path_ok = (math.random(1, 100) <= percent_extra_paths)
      local nx, ny = x + 2 * nbor_dirs[i][1], y + 2 * nbor_dirs[i][2]
      if already_visited[xy_str(nx, ny)] and not is_extra_path_ok then
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
  grid = {}               -- Set up an empty grid.
  for x = 1, grid_w do
    grid[x] = {}
  end
  drill_from(1, 1)        -- Drill out paths to make the maze.

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
