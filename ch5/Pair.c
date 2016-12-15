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
  lua_rawgeti(L, 2, 1);  // 2, 1 = idx in stack, idx in table
      // stack = [self, p, p[1]]
  lua_rawgeti(L, 2, 2);
      // stack = [self, p, p[1], p[2]]
  lua_Number x = lua_tonumber(L, -2);  // p[1]
  lua_Number y = lua_tonumber(L, -1);  // p[2]
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


// -- Internal functions --

// Clear the stack and set up a new Pair instance on it.
void push_new_pair(lua_State *L, lua_Number x, lua_Number y) {

  // Clear the stack.
  lua_settop(L, 0);
    // stack = []

  // Set up the new resulting Pair instance.
  lua_newtable(L);
    // stack = [t (the new table)]
  lua_pushnumber(L, x);
    // stack = [t, x]
  lua_rawseti(L, -2, 1);  // t[1] = x
    // stack = [t]
  lua_pushnumber(L, y);
    // stack = [t, y]
  lua_rawseti(L, -2, 2);  // t[2] = y
    // stack = [t]
  lua_pushvalue(L, -1);
    // stack = [t, t]
  Pair_new(L);
    // stack = [new Pair from t]
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
  lua_Number p[2] = {pair->x, pair->y};
  lua_Number q[2];
  for (int i = 0; i < 2; ++i) {
    lua_pushnumber(L, i + 1);
      // stack = [self, other, i + 1]
    lua_gettable(L, 2);
      // stack = [self, other, other[i + 1]]
    if (lua_type(L, -1) != LUA_TNUMBER) {
      return luaL_argerror(L, 2, "bad 2nd addend");
    }
    q[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
      // stack = [self, other]
  }
  lua_settop(L, 0);
    // stack = []

  // Set up a new table with the sum.
  push_new_pair(L, p[0] + q[0], p[1] + q[1]);

  return 1;
}

// Pair_mt:mul(scalar)
int Pair_mt_mul(lua_State *L) {

  // Expected: stack = [self, scalar]

  // Extract the needed values.
  Pair *pair = (Pair *)luaL_checkudata(L, 1, Pair_metatable);
  lua_Number scalar = luaL_checknumber(L, 2);

  // Set up the new resulting Pair instance.
  push_new_pair(L, pair->x * scalar, pair->y * scalar);

  return 1;
}

// Pair_mt:eq(other)
int Pair_mt_eq(lua_State *L) {

  // Expected: stack = [self (p), other (q)]

  // Extract the pairs p, q from the stack.
  Pair *p = (Pair *)luaL_checkudata(L, 1, Pair_metatable);
  Pair *q = (Pair *)luaL_testudata(L, 2, Pair_metatable);

  // Push true or false onto the stack.
  if (q == NULL) {
    lua_pushboolean(L, 0);  // If q is not a Pair, return false.
  } else {
    lua_pushboolean(L, p->x == q->x && p->y == q->y);
  }

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
      {"__eq",    Pair_mt_eq},
      {"__mul",   Pair_mt_mul},
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
