// Pair.h
//
// Pair is a simple userdata type, defined in C, which supports
// basic operations on (x, y) pairs.
//
// Example usage:
//
//   local Pair = require 'Pair'
//
//   local p = Pair:new {1, 2}
//   local q = Pair:new {3, 4}
//   print(p + q)      -- Prints out '4,6'.
//   print(p.x + p.y)  -- Prints out '3'.
//
//   TODO Confirm that that example actually works.
//

#include "lua.h"

int luaopen_Pair(lua_State *L);
