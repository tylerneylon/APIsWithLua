#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include "util.h"


// Globals.

static double start;
static int    score = 0;


// Functions.

lua_State *init() {

  // Initialize the terminal state for drawing an input.
  system("stty raw");
  fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL) | O_NONBLOCK);

  start = gettime();               // Set up our timer.

  lua_State *L = luaL_newstate();  // Set up the Lua state.
  luaL_openlibs(L);

  // These two lines are like this Lua statement: eatyguy = require 'eatyguy'
  luaL_dofile(L, "eatyguy.lua");
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);                // Clear the stack.
  call(L, "eatyguy", "init", "");  // Call eatyguy.init().

  return L;
}

void done(char *msg, int score) {
  system("stty cooked");  // Restore terminal input and echo settings.
  system("tput reset");   // Restore terminal colors and clear screen.
  printf("%s\n", msg);
  printf("Final score: %d\n", score);
  exit(0);
}

void loop(lua_State *L) {
  int    key     = getkey();
  double elapsed = gettime() - start;

  // Exit if the user hits esc or the q key.
  if (key == 27 || key == 'q' || key == 'Q') done("Goodbye!", score);

  // Execute one game loop and pause for 32 ms.
  char *game_state;
  call(L, "eatyguy", "loop", "di>si", elapsed, key, &game_state, &score);
  if (strcmp(game_state, "playing") != 0) done(game_state, score);
  tinysleep(0.032);  // 32 ms
}


// Main.

int main() {
  lua_State *L = init();
  while (1) loop(L);
  return 0;
}
