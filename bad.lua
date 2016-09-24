local strict = require('strict')

local _ENV = strict.new_env()

local bad = {}

function bad.f()
  undefined1 = 42
end

function bad.g()
  undefined2 = 42
end

bad.f()

return bad
