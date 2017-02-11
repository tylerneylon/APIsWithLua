// eatyguy2.c
//
// Loads eatyguy2.lua and runs eatyguy.init(),
// followed by eatyguy.loop() in a loop.
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>

// 27 is the decimal representation of Esc in ASCII.
#define ESC_KEY 27

// Internal functions.

double gettime() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec + 1e-6 * tv.tv_usec;
}

// This code is part of the file eatyguy2.c, which is the same
// as eatyguy1.c except for lines in bold.

int getkey() {

  // Make reading from stdin non-blocking.
  int flags = fcntl(STDIN_FILENO, F_GETFL);
  fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);

  int ch = getchar();

  // Turn off non-blocking I/O. On some systems, leaving stdin
  // non-blocking will also leave stdout non-blocking, which
  // can cause printing errors.
  fcntl(STDIN_FILENO, F_SETFL, flags);
  return ch;
}


void start() {
  // Terminal setup.
  system("tput setab 0");    // Use a black background.
  system("tput clear");      // Clear the screen.
  system("tput civis");      // Hide the cursor.
  system("stty raw -echo");  // Improve access to keypresses.
}

void done() {

  // Put the terminal back into a decent state.
  system("stty cooked echo");  // Undo init call to "stty raw".
  system("tput reset");        // Reset colors and clear screen.

  exit(0);
}


// Lua-visible functions.

// Lua: set_color('b' or 'f', <color>).
int set_color(lua_State *L) {
  const char *b_or_f = lua_tostring(L, 1);
  int color = lua_tonumber(L, 2);
  char cmd[1024];
  snprintf(cmd, 1024, "tput seta%s %d", b_or_f, color);
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

  start();

  // Create a Lua state and load the module.
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  // Make our Lua-callable functions visible to Lua.
  lua_register(L, "set_color", set_color);
  lua_register(L, "set_pos",   set_pos);
  lua_register(L, "timestamp", timestamp);

  // Load eatyguy2.lua and run the init() function.
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

    int c = getkey();
    if (c == ESC_KEY || c == 'q' || c == 'Q') done();
  }

  return 0;
}
