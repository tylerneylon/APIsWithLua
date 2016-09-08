// mymodule.c

#include "lua.h"
#include <stdio.h>

int luaopen_mymodule(lua_State *L) {
  printf("luaopen_mymodule() was called!\n");
  lua_newtable(L);
  return 1;  // Return the empty table.
}
