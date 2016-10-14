// eatyguy1.c
//
// Loads eatyguy1.lua and runs eatyguy.init().
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdlib.h>


// Lua-visible functions.

int set_color(lua_State *L) {
  int color = lua_tonumber(L, 1);
  char cmd[1024];
  snprintf(cmd, 1024, "tput setab %d", color);
  system(cmd);
  return 0;  // 0 is the number of Lua-visible return values.
}


// Main.

int main() {

  // Create a Lua state and load the module.
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  luaL_dofile(L, "eatyguy1.lua");
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);

  // Make the set_color function visible to Lua.
  lua_pushcfunction(L, set_color);
  lua_setglobal(L, "set_color");

  // Run the init() function.
  lua_getglobal(L, "eatyguy");
  lua_getfield(L, -1, "init");  // -1 means stack top.
  lua_call(L, 0, 0);            // 0, 0 = #args, #retvals

  return 0;
}
