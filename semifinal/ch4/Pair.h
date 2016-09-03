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
//   local r = p + q * 2  -- Now r = {7, 10}.
//

#include "lua.h"

int luaopen_Pair(lua_State *L);
