-- util.lua
--
-- Define the functions set_color and set_pos so that they cache
-- the strings returned from tput in order to reduce the number
-- of tput calls.


-- Local functions like memoized_cmd won't be globally visible
-- after this script completes.

local memoized_strs = {}  -- Maps cmd -> str.

local function memoized_cmd(shell_cmd)
  if not memoized_strs[shell_cmd] then
    local pipe = io.popen(shell_cmd)
    memoized_strs[shell_cmd] = pipe:read()
    pipe:close()
  end
  io.write(memoized_strs[shell_cmd])
end


-- Global functions will remain visible after this script
-- completes.

function set_color(b_or_f, color)
  assert(b_or_f == 'b' or b_or_f == 'f')
  memoized_cmd('tput seta' .. b_or_f .. ' ' .. color)
end

function set_pos(x, y)
  memoized_cmd(('tput cup %d %d'):format(y, x))
end
