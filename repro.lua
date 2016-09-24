local strict = require 'strict'
local _ENV   = strict.new_env()

local bad    = require 'bad'
bad.g()

function hello()
	print(zonk)
end

wonk = 4

--hello()
