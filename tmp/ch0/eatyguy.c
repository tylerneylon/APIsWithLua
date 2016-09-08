#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include "util.h"


// Functions.

lua_State *init() {

  // Initialize the terminal state for drawing an input.
  //system("stty raw");
  //fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL) | O_NONBLOCK);

  lua_State *L = luaL_newstate();  // Set up the Lua state.
  luaL_openlibs(L);

  // These two lines are like this Lua statement: eatyguy = require 'eatyguy'
  luaL_dofile(L, "eatyguy.lua");
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);                // Clear the stack.
  call(L, "eatyguy", "init", "");  // Call eatyguy.init().

  return L;
}

void done(char *msg) {
  //system("stty cooked");  // Restore terminal input and echo settings.
  //system("tput reset");   // Restore terminal colors and clear screen.
  printf("%s\n", msg);
  exit(0);
}

void loop(lua_State *L) {
  int    key     = getkey();

  // Exit if the user hits esc or the q key.
  if (key == 27 || key == 'q' || key == 'Q') done("Goodbye!");

  tinysleep(0.032);  // 32 ms
}


// Main.

int main() {
  lua_State *L = init();
  //while (1) loop(L);
  return 0;
}
