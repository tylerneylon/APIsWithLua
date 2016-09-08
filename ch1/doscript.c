// doscript.c

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

int main() {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  luaL_dofile(L, "script.lua");

  return 0;
}
