// runmodule.c
//
// Loads eatyguy0.lua and runs eatyguy.init().
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

int main() {

  // Create a Lua state and load the module.
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  luaL_dofile(L, "eatyguy0.lua");
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);

  // Run the init() function.
  lua_getglobal(L, "eatyguy");
  lua_getfield(L, -1, "init");  // -1 means stack top.
  lua_call(L, 0, 0);            // 0, 0 = #args, #retvals

  return 0;
}
