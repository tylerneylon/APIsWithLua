-- eatyguy0.lua

local eatyguy = {}


-- Globals.

local percent_extra_paths = 15
local grid                = nil     -- grid[x][y]: falsy = wall.
local grid_w, grid_h      = nil, nil


-- Internal functions.

local function is_in_bounds(x, y)
  return (1 <= x and x <= grid_w and
          1 <= y and y <= grid_h)
end

local function get_neighbor_directions(x, y, percent_extra)
  -- percent_extra is the percent chance of adding extra paths.
  percent_extra = percent_extra or 0
  local neighbor_directions = {}
  local all_directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
  for _, direction in pairs(all_directions) do
    local nx, ny = x + 2 * direction[1], y + 2 * direction[2]
    local is_extra_ok = (math.random(100) <= percent_extra)
    -- Add `direction` if the neighbor is not yet in a path, or
    -- if we randomly got an extra ok using percent_extra.
    if is_in_bounds(nx, ny) and
       (not grid[nx][ny] or is_extra_ok) then
      table.insert(neighbor_directions, direction)
    end
  end
  return neighbor_directions
end

local function drill_path_from(x, y)
  grid[x][y] = 'open'
  local neighbor_directions = get_neighbor_directions(x, y)
  while #neighbor_directions > 0 do
    local direction = table.remove(neighbor_directions,
                          math.random(#neighbor_directions))
    grid[x + direction[1]][y + direction[2]] = 'open'
    drill_path_from(x + 2 * direction[1], y + 2 * direction[2])
    neighbor_directions = get_neighbor_directions(x, y,
                                          percent_extra_paths)
  end
end


-- Public functions.

function eatyguy.init()

  -- Set up the grid size and pseudorandom number generation.
  grid_w, grid_h = 39, 21
  math.randomseed(os.time())

  -- Build the maze.
  grid = {}
  for x = 1, grid_w do grid[x] = {} end
  drill_path_from(1, 1)

  -- Draw the maze.
  for y = 0, grid_h + 1 do
    for x = 0, grid_w + 1 do
      -- This line is like: chars = (grid[x][y] ? '  ' : '##').
      local chars = (grid[x] and grid[x][y]) and '  ' or '##'
      io.write(chars)
    end
    io.write('\n')  -- Move cursor to next row.
  end
end

return eatyguy
