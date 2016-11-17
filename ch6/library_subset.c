// library_subset.c

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

typedef enum {
  mode_all_libs,
  mode_some_libs,
  mode_base_only
} Mode;

int main() {

  lua_State *L = luaL_newstate();
  int set_global = 1;

  // Choose how many libraries to work with.
  Mode mode = mode_all_libs;  // Change this value to explore.
  switch (mode) {

    case mode_all_libs:
      luaL_openlibs(L);
      break;

    case mode_some_libs:
      luaL_requiref(L, "package", luaopen_package, set_global);
      luaL_requiref(L, "string", luaopen_string, set_global);
      luaL_requiref(L, "table", luaopen_table, set_global);
      luaL_requiref(L, "math", luaopen_math, set_global);
      // Fall through to also include the next case.

    case mode_base_only:
      luaL_requiref(L, "_G", luaopen_base, set_global);
      break;
  }

  luaL_dofile(L, "run_bash.lua");

  return 0;
}

