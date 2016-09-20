// loadmodule.c
//
// Loads mymodule.lua but doesn't call any functions in it.
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

int main() {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  luaL_dofile(L, "mymodule.lua");
  lua_setglobal(L, "mymodule");
  lua_settop(L, 0);

  return 0;
}
