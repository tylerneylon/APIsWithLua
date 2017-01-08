// lua_pcall.c

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>

int my_error_handler(lua_State *L) {
  // Push a stack trace string onto the stack.
  // This augmented string will effectively replace the simpler
  // error message that comes directly from the Lua error.
  luaL_traceback(L, L, lua_tostring(L, -1), 1);
  return 1;
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

  lua_register(L, "my_error_handler", my_error_handler);
  lua_register(L, "fn_that_throws",   fn_that_throws);
  lua_register(L, "middle_fn",        middle_fn);

  // Call middle_fn().
  lua_pushcfunction(L, my_error_handler);
  lua_getglobal(L, "middle_fn");
  int status = lua_pcall(L, 0, 0, -2);
  if (status != LUA_OK) {
    // Print the error.
    printf("Looks like lua_pcall() caught an error:\n%s\n",
           lua_tostring(L, -1));
    // Pop the error message from the stack.
    lua_pop(L, 1);
  }

  printf("Done!\n");

  return 0;
}
