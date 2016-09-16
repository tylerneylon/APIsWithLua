// traceback.c
//
// Demonstrate how to print a Lua stack trace from C.
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

// Print out the current call stack, preceded by the custom
// message "zounds!" which is an exclamation of surprise.
int print_stack(lua_State *L) {
  luaL_traceback(L, L, "zounds!", 0);
  printf("%s\n", lua_tostring(L, -1));
  lua_pop(L, 1);
  return 0;
}

int main() {

  // Set up a Lua state and register the print_stack function.
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_register(L, "print_stack", print_stack);

  // Run trackback.lua, which defines functions a() and b().
  luaL_dofile(L, "traceback.lua");

  // Call a(), which will indirectly call print_stack().
  lua_getglobal(L, "a");
  lua_call(L, 0, 0);
  printf("That wasn't an error! Just a stack trace.\n");

  return 0;
}
