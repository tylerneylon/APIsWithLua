-- fps_test2.lua
--
-- Test how quickly we can draw to the entire screen in different colors.
--

--[[

Test results:

On my system (macOS, 2.7 GHz quad core i7), with 252 lines, 71 cols, I hit a
little over 60 fps with no in-script delay. With a 16 ms delay, I was getting
around 30 fps.

These numbers dropped a little if I increased the number of color changes. The
above numbers are for an average of 1 color change per 300 characters. If that
probability increases to 1 change per 10 characters, then the reported frame
rate drops to around 40 fps, but visually it appear to be much worse - closer to
1 fps by my guess.

If I don't cache the tput output values, the reported fps drops below 2.
(This is at 1 color change per 300 characters on average.)

--]]

-- Requires.

local posix = require 'posix'


-- File globals (local to this file).

local lines, cols
local color_str   = {}   -- Each item is a string to set the given colors.
local num_rc      = 200  -- Total number of values to be set in random_colors.


-- Functions.

local function str_from_cmd(cmd)
  local p = io.popen('tput ' .. cmd)
  local s = p:read()
  p:close()
  return s
end

local function init_random_colors()
  for i = 1, num_rc do
    local f = math.random(0, 255)
    local b = math.random(0, 255)
    local s = str_from_cmd('setaf ' .. f)
    s = s ..  str_from_cmd('setab ' .. b)
    table.insert(color_str, s)
  end
end

-- Run a tput command.
local function run(cmd)
  os.execute('tput ' .. cmd)
end

local function set_to_random_color()
  local i = math.random(#color_str)
  io.write(color_str[i])

  --[[
  local f = math.random(0, 255)
  local b = math.random(0, 255)
  run('setaf ' .. f)
  run('setab ' .. b)
  io.flush()
  --]]
end

local function num_from_cmd(cmd)
  p = io.popen(cmd)
  n = tonumber(p:read())
  p:close()
  return n
end

local function draw_frame()
  run 'home'

  for y = 0, lines - 3 do
    for x = 0, cols - 3 do
      --[[
      local f = math.random(0, 255)
      local b = math.random(0, 255)
      run('setaf ' .. f)
      run('setab ' .. b)
      --]]
      
      if math.random(1, 300) <= 1 then set_to_random_color() end
      io.write('*')
      --io.flush()
    end
    io.write('\n')
  end
  io.flush()
end

local function main()
  lines = num_from_cmd 'tput lines'
  cols  = num_from_cmd 'tput cols'
  init_random_colors()

  local start = posix.gettimeofday()
  start = start.sec + start.usec * 1e-6

  local num_frames_shown = 0

  while true do
    draw_frame()
    local sec, nsec = 0, 16e6  -- 0.016 seconds.
    --posix.nanosleep(sec, nsec)
    --os.execute('sleep 0.1')

    -- Evaluate and print the current average framerate.
    num_frames_shown = num_frames_shown + 1
    local now = posix.gettimeofday()
    now = now.sec + now.usec * 1e-6
    local seconds_passed = now - start
    local avg_fps = num_frames_shown / seconds_passed
    io.write('average fps = ' .. tostring(avg_fps))
    io.flush()
  end
end


-- Run the script.

main()
