// eatyguy1.c
//
// TODO Update this description.
//

#include <fcntl.h>
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

int traceback(lua_State *L) {
  luaL_traceback(L, L, "<a>", 0);
  system("stty cooked");  // Undo earlier call to "stty raw".
  system("tput reset");   // Reset terminal colors and clear the screen.
  printf("err:\n%s\n", lua_tostring(L, -1));
  exit(1);
}

// Most of this function is from a similar function in the book Programming in
// Lua by Roberto Ierusalimschy, 3rd edition.
void dump_stack(lua_State *L) {
  int top = lua_gettop(L);
  for (int i = 1; i <= top; ++i) {
    int t = lua_type(L, i);
    switch(t) {
      case LUA_TSTRING:
        {
          printf("'%s'", lua_tostring(L, i));
          break;
        }
      case LUA_TBOOLEAN:
        {
          printf(lua_toboolean(L, i) ? "true" : "false");
          break;
        }
      case LUA_TNUMBER:
        {
          printf("%g", lua_tonumber(L, i));
          break;
        }
      default:
        {
          lua_getglobal(L, "tostring");
          lua_pushvalue(L, i);
          lua_call(L, 1, 1);  // 1 input, 1 output
          printf("%s", lua_tostring(L, -1));
          lua_pop(L, 1);
          break;
        }
    }
    printf("  ");  // separator
  }
  printf("\n");
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

  lua_pushcfunction(L, traceback);
  dump_stack(L);

  lua_getglobal(L, "eatyguy");
  dump_stack(L);
  lua_getfield(L, -1, "init");  // -1 means stack top.
  dump_stack(L);
  int err = lua_pcall(L, 0, 0, 1);            // 0, 0 = #args, #retvals
  if (err) {
    system("stty cooked");  // Undo earlier call to "stty raw".
    system("tput reset");   // Reset terminal colors and clear the screen.
    printf("[[1]] err:\n%s\n", lua_tostring(L, -1));
    exit(1);
  }

  lua_getglobal(L, "eatyguy");
  dump_stack(L);
  while (1) {
    // Call eatyguy.loop().
    lua_getfield(L, -1, "loop");
    dump_stack(L);
    err = lua_pcall(L, 0, 0, 1);  // XXX
    if (err) {
      system("stty cooked");  // Undo earlier call to "stty raw".
      system("tput reset");   // Reset terminal colors and clear the screen.
      printf("[[2]] err:\n%s\n", lua_tostring(L, -1));
      exit(1);
    }

    int c = getchar();
    if (c == 27 || c == 'q' || c == 'Q') done();
  }

  return 0;
}
