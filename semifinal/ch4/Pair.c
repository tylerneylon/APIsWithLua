// Pair.c
//
// When this module is loaded, it sets up two tables:
// * Pair, which is the class itself, and
// * Pair_mt, the metatable of Pair.
// Pair_mt contains metamethods such as __index.
// Pair contains the new() method so the user can create new
// Pairs by using the familiar pattern:
//
// local p = Pair:new{12, 34}.
//

#include "Pair.h"

#include "lauxlib.h"

#include <string.h>


// -- Macros and types --

#define Pair_metatable "Pair"

typedef struct {
  lua_Number x;
  lua_Number y;
} Pair;


// -- Methods --

// Pair:new(p)
int Pair_new(lua_State *L) {

  // Extract the x, y data from the stack.
  luaL_checktype(L, 2, LUA_TTABLE);
      // stack = [self, p]
  lua_rawgeti(L, 2, 1);  // 1, 1 = idx in stack, idx in table
      // stack = [self, p, p[1]]
  lua_rawgeti(L, 2, 2);
      // stack = [self, p, p[1], p[2]]
  lua_Number x = lua_tonumber(L, -2);
  lua_Number y = lua_tonumber(L, -1);
  lua_settop(L, 0);
      // stack = []

  // Create a Pair instance and set its metatable.
  Pair *pair = (Pair *)lua_newuserdata(L, sizeof(Pair));
      // stack = [pair]
  luaL_getmetatable(L, Pair_metatable);
      // stack = [pair, mt]
  lua_setmetatable(L, 1);
      // stack = [pair]

  // Set up the C data.
  pair->x = x;
  pair->y = y;

  return 1;
}


// -- Metamethods --

// Pair_mt:index(key)
// This is used to enable p.x and p.y dereferencing on Pair p.
// This also supports p[1] and p[2] lookups.
int Pair_mt_index(lua_State *L) {

  // Expected: stack = [self, key]
  Pair *pair = (Pair *)luaL_checkudata(L, 1, Pair_metatable);

  // Find the key value as either 1 (x) or 2 (y).
  int key = 0;
  int t = lua_type(L, 2);
  if (t == LUA_TNUMBER) {
    int ok;
    key = (int)lua_tointegerx(L, 2, &ok);
    if (!ok || (key != 1 && key != 2)) key = 0;
  } else if (t == LUA_TSTRING) {
    const char *str_key = lua_tostring(L, 2);
    if (strcmp(str_key, "x") == 0) key = 1;
    if (strcmp(str_key, "y") == 0) key = 2;
  }

  // Push the value.
  if (key) {
    lua_pushnumber(L, key == 1 ? pair->x : pair->y);
  } else {
    lua_pushnil(L);
  }

  return 1;
}

// Pair_mt:add(other)
int Pair_mt_add(lua_State *L) {

  // Expected: stack = [self, other]
  // other may be a Pair or a table of the form {x, y}.
  
  // Extract the pairs p, q from the stack.
  Pair *pair = (Pair *)luaL_checkudata(L, 1, Pair_metatable);
  int p[2] = {pair->x, pair->y};
  int q[2];
  for (int i = 0; i < 2; ++i) {
    int t = lua_geti(L, 2, i + 1);
      // stack = [self, other, other[i + 1]]
    if (t != LUA_TNUMBER) {
      return luaL_argerror(L, 2, "bad 2nd addend");
    }
    q[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
      // stack = [self, other]
  }
  lua_settop(L, 0);
    // stack = []

  // Set up a new table with the sum.
  lua_newtable(L);
    // stack = [t = {}]
  for (int i = 0; i < 2; i++) {
    lua_pushnumber(L, p[i] + q[i]);
    // stack = [t, p[i] + q[i]]
    lua_seti(L, 1, i + 1);
    // stack = [t]
  }

  // Call Pair:new() on the table t.
  lua_pushvalue(L, -1);
    // stack = [t, t]
  Pair_new(L);
    // stack = [.., new Pair from t]

  return 1;
}


// -- Luaopen function --

int luaopen_Pair(lua_State *L) {

  // The user may pass in values here,
  // but we'll ignore those values.
  lua_settop(L, 0);

    // stack = []

  // If this metatable already exists, the library is already
  // loaded.
  if (luaL_newmetatable(L, Pair_metatable)) {

    // stack = [mt]

    static struct luaL_Reg metamethods[] = {
      {"__index", Pair_mt_index},
      {"__add",   Pair_mt_add},
      {NULL, NULL}
    };
    luaL_setfuncs(L, metamethods, 0);
    lua_pop(L, 1);  // The table is saved in the Lua's registry.

    // stack = []
  }

  static struct luaL_Reg fns[] = {
    {"new", Pair_new},
    {NULL, NULL}
  };

  luaL_newlib(L, fns);  // Push a new table with fns key/vals.

    // stack = [Pair = {new = new}]

  return 1;  // Return the top item, the Pair table.
}
