-- eatyguy.lua

local eatyguy = {}

-- Parameters.

local percent_extra_paths = 30
local grid       = nil  -- grid[x][y] = what's at that spot; falsy == wall.
local grid_w, grid_h = nil, nil

-- Internal functions.

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
      local chars = (grid[x] and grid[x][y]) and '  ' or '##'
      io.write(chars)
    end
    io.write('\n')  -- Move cursor to next row.
  end
end

return eatyguy
