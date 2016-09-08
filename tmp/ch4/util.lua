-- util.lua
--
-- Define the functions set_color and set_pos so that they cache the strings
-- returned from tput in order to reduce the number of tput calls.


-- Local functions won't be globally visible after this script completes.

local cached_strs = {}  -- Maps cmd -> str.

local function cached_cmd(cmd)
  if not cached_strs[cmd] then
    p = io.popen(cmd)
    cached_strs[cmd] = p:read()
    p:close()
  end
  io.write(cached_strs[cmd])
end


-- Global functions will remain visible after this script completes.

function set_color(b_or_f, color)
  assert(b_or_f == 'b' or b_or_f == 'f')
  cached_cmd('tput seta' .. b_or_f .. ' ' .. color)
end

function set_pos(x, y)
  cached_cmd('tput cup ' .. y .. ' ' .. x)
end
