// runmodule2.c
//
// Loads eatyguy.lua and runs eatyguy.init().
//

#include <stdlib.h>
#include <sys/time.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"


// Internal functions.

double gettime() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec + 1e-6 * tv.tv_usec;
}


// Lua-visible functions.

// Lua: set_color('b' or 'g', <color>).
int set_color(lua_State *L) {
  const char *b_or_g = lua_tostring(L, 1);
  int color = lua_tonumber(L, 2);
  char cmd[1024];
  snprintf(cmd, 1024, "tput seta%s %d", b_or_g, color);
  system(cmd);
  return 0;
}

// Lua: set_pos(x, y).
int set_pos(lua_State *L) {
  int x = lua_tonumber(L, 1);
  int y = lua_tonumber(L, 2);
  char cmd[1024];
  // The 'tput cup' command accepts y before x; not a typo.
  snprintf(cmd, 1024, "tput cup %d %d", y, x);
  system(cmd);
  return 0;
}

// Lua: timestamp().
// Return a high-resolution timestamp in seconds.
int timestamp(lua_State *L) {
  lua_pushnumber(L, gettime());
  return 1;
}


// Main.

int main() {

  system("tput clear");  // Clear the screen.
  system("tput civis");  // Hide the cursor.

  // Create a Lua state and load the module.
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  // Make our Lua-callable functions visible to Lua.
  lua_register(L, "set_color", set_color);
  lua_register(L, "set_pos",   set_pos);
  lua_register(L, "timestamp", timestamp);

  // Load eatyguy2 and run the init() function.
  luaL_dofile(L, "eatyguy2.lua");
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);
  lua_getglobal(L, "eatyguy");
  lua_getfield(L, -1, "init");  // -1 means stack top.
  lua_call(L, 0, 0);            // 0, 0 = #args, #retvals

  lua_getglobal(L, "eatyguy");
  while (1) {
    // Call eatyguy.loop().
    lua_getfield(L, -1, "loop");
    lua_call(L, 0, 0);
  }

  return 0;
}
