#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include "clua.h"


// Globals.

static double start;


// Functions.

double gettime() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec + 1e-6 * tv.tv_usec;
}

lua_State *init() {

  // Initialize the terminal state for drawing an input.
  system("stty raw");
  fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL) | O_NONBLOCK);

  // Set up our timer.
  start = gettime();

  // Set up the Lua state and load eatyguy.lua.
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  luaL_dofile(L, "eatyguy.lua");
  // The Lua stack now has the return values from the script.
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);  // Clear the stack.
  call(L, "eatyguy", "init", "");

  return L;
}

void done() {
  system("stty cooked");
  system("tput reset");
  exit(0);
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

void loop(lua_State *L) {

  int    key     = getkey();
  double elapsed = gettime() - start;

  // Exit if the user hits esc or the q key.
  if (key == 27 || key == 'q' || key == 'Q') done();

  call(L, "eatyguy", "loop", "di", elapsed, key);

  struct timespec delay = { .tv_sec = 0, .tv_nsec = 32e6 };  // 32 ms
  nanosleep(&delay, NULL);
}


// Main.

int main() {
  lua_State *L = init();
  while (1) loop(L);
  return 0;
}
