local function low()
  error('thrown in low()')
end

local function middle()
  low()
end

local function high()
  middle()
end

print(pcall(high))
print('last line')
