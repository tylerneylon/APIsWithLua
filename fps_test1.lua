-- fps_test1.lua
--
-- Test how quickly we can draw to the entire screen in different colors.
--


-- Requires.

local posix = require 'posix'


-- File globals (local to this file).

local lines, cols


-- Functions.

-- Run a tput command.
local function run(cmd)
  os.execute('tput ' .. cmd)
end

local function num_from_cmd(cmd)
  p = io.popen(cmd)
  n = tonumber(p:read())
  p:close()
  return n
end

local function draw_frame()
  run 'home'

  for y = 0, lines - 1 do
    for x = 0, cols - 3 do
      local f = math.random(0, 255)
      local b = math.random(0, 255)
      run('setaf ' .. f)
      run('setab ' .. b)
      io.write('*')
      io.flush()
    end
    io.write('\n')
  end
end

local function main()
  lines = num_from_cmd 'tput lines'
  cols  = num_from_cmd 'tput cols'

  while true do
    draw_frame()
  end
end


-- Run the script.

main()
