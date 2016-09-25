t = {}
x = 3
do
  local _ENV = t
  x = 4
end
print(x, t.x)
