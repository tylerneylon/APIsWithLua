// interpreter.c
//

#include "interpreter.h"

#include "lauxlib.h"
#include "lualib.h"

#include <stdio.h>
#include <stdlib.h>

int accept_and_run_a_line(lua_State *L) {

  char buff[2048];

  // Read input and exit early if there is an end of stream.
  printf("> ");
  if (!fgets(buff, sizeof(buff), stdin)) {
    printf("\n");
    return 0;
  }

  // Try to run the line, printing errors if there are any.
  int error = luaL_loadstring(L, buff);
  if (!error) error = lua_pcall(L, 0, 0, 0);
  if (error) {
    fprintf(stderr, "%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
  }

  return 1;
}
