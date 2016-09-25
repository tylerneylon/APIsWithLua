_ENV = {_G = _G, load = load, print = print}
pizza = 'super'
load("pizza = 'awesome'")()
print(_ENV.pizza, _G.pizza)
