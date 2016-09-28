// lua_error.c

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>

int fn(lua_State *L) {
  lua_pushstring(L, "thrown from fn()!");
  lua_error(L);
  return 1;
}

int main() {

  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_register(L, "fn", fn);
  
  // Call fn().
  lua_getglobal(L, "fn");
  lua_call(L, 0, 0);

  printf("Done!\n");

  return 0;
}
