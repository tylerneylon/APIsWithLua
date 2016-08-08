// eatyguy1.c
//
// Load eatyguy1.lua and run it in the order below.
//
//   -- Lua-ish pseucode representing the order of events.
//   eatyguy.init()
//   while true do
//     eatyguy.loop(key)
//     sleep(0.016)
//   end
//
//

#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"


// Internal functions.

double gettime() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec + 1e-6 * tv.tv_usec;
}

int getkey() {

  // We care about two cases:
  // Case 1: A sequence of the form 27, 91, X; return X.
  // Case 2: For any other sequence, return each int separately.

  int ch = getchar();
  if (ch == 27) {
    int next = getchar();
    if (next == 91) return getchar();
    // If we get here, then we're not in a 27, 91, X sequence.
    ungetc(next, stdin);
  }
  return ch;
}

void sleephires(double sec) {
  long s = (long)floor(sec);
  long n = (long)floor((sec - s) * 1e9);
  struct timespec delay = { .tv_sec = s, .tv_nsec = n };
  nanosleep(&delay, NULL);
}

void start() {

  // Terminal setup.
  system("tput clear");  // Clear the screen.
  system("tput civis");  // Hide the cursor.
  system("stty raw");    // Improve access to keypresses from stdin.

  // Make reading from stdin non-blocking.
  fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL) | O_NONBLOCK);
}

void done() {

  // Put the terminal back into a decent state.
  system("stty cooked");  // Undo earlier call to "stty raw".
  system("tput reset");   // Reset terminal colors and clear the screen.

  exit(0);
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

  start();

  // Create a Lua state and load the module.
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  // Make our Lua-callable functions visible to Lua.
  lua_register(L, "set_color", set_color);
  lua_register(L, "set_pos",   set_pos);
  lua_register(L, "timestamp", timestamp);

  // Load eatyguy2 and run the init() function.
  luaL_dofile(L, "eatyguy1.lua");
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);

  lua_getglobal(L, "eatyguy");
  lua_getfield(L, -1, "init");  // -1 means stack top.
  lua_call(L, 0, 0);            // 0, 0 = #args, #retvals

  lua_getglobal(L, "eatyguy");
  while (1) {
    int key = getkey();
    if (key == 27 || key == 'q' || key == 'Q') done();

    // Call eatyguy.loop().
    lua_getfield(L, -1, "loop");
    lua_pushnumber(L, key);
    lua_call(L, 1, 0);

    sleephires(0.016);  // Sleep for 16ms.
  }

  return 0;
}
