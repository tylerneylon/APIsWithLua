-- double_err.lua
--
-- Check the behavior of a message handler that causes an error itself.
--

local function msgh(err)
  if err == 'from msgh v1' then
    return 'from msgh v2'
  else
    error('from msgh v1')
  end
end

local function throw_an_err()
  error('from throw_an_err()')
end

print(xpcall(throw_an_err, msgh))
