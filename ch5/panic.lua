-- panic.lua

local function low()
  error('thrown from low')
end

local function middle()
  low()
end

local function high()
  middle()
end

high()
print('Done!')
