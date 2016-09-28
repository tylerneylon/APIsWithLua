function add_a()
  a = 3
end

print(('1: a = %s'):format(a))

local _ENV = {_G = _G, add_a = add_a, print = print}

print(('2: a = %s'):format(a))

function wrap_call(fn, t)
  local _ENV = t
  fn()
end

local t = {}
wrap_call(add_a, t)

print(('3: a = %s'):format(a))
print(('4: t.a = %s'):format(t.a))
print(('4: _G.a = %s'):format(_G.a))



