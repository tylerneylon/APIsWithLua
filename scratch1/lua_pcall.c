// lua_pcall.c

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>

int my_error_handler(lua_State *L) {
  luaL_traceback(L, L, lua_tostring(L, -1), 1);
  fprintf(stderr, "%s\n", lua_tostring(L, -1));
  return 0;
}

int fn_that_throws(lua_State *L) {
  lua_pushstring(L, "thrown from fn()!");
  lua_error(L);
  return 1;
}

int middle_fn(lua_State *L) {
  lua_getglobal(L, "fn_that_throws");
  lua_call(L, 0, 0);
  return 0;
}

int main() {

  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_register(L, "fn_that_throws", fn_that_throws);
  lua_register(L, "middle_fn", middle_fn);
  
  // Call fn().
  lua_pushcfunction(L, my_error_handler);
  lua_getglobal(L, "middle_fn");
  lua_pcall(L, 0, 0, -2);

  printf("Done!\n");

  return 0;
}
