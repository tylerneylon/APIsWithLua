-- test_pair.lua
--
-- A simple test to help verify that the Pair class is
-- working as desired.
--

local Pair = require 'Pair'

local p = Pair:new{ 1,   2}
local q = Pair:new{-1.5, 3}

assert(p.x ==  1)
assert(q.x == -1.5)

local r = p + q

assert(r.x == -0.5)
assert(r.y ==  5)

local s = Pair:new{-0.5, 5}

assert(r == s)
assert(p ~= q)

-- If we get here, then no assert failed.
print('Test passed!')
