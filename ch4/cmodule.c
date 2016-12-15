// cmodule.c

#include "cmodule.h"
#include <stdio.h>

int luaopen_cmodule(lua_State *L) {
  printf("luaopen_cmodule() was called!\n");
  lua_newtable(L);
  return 1;  // Return the empty table.
}
