// eatyguy9.c
//
// Load eatyguy9.lua and run it in the order below.
//
//   -- Lua-ish pseudocode representing the order of events.
//   eatyguy.init()
//   while true do
//     eatyguy.loop(state)  -- state has keys 'clock' and 'key'.
//     sleep(0.016)
//   end
//

#include "Pair.h"

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

// 27 is the decimal representation of Esc in ASCII.
#define ESC_KEY 27


// Internal functions.

double gettime() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec + 1e-6 * tv.tv_usec;
}

int getkey(int *is_end_of_seq) {

  // Make reading from stdin non-blocking.
  int flags = fcntl(STDIN_FILENO, F_GETFL);
  fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);

  // We care about two cases:
  // Case 1: A sequence of the form 27, 91, X; return X.
  // Case 2: For any other sequence, return each int separately.

  *is_end_of_seq = 0;
  int ch = getchar();
  if (ch == 27) {
    int next = getchar();
    if (next == 91) {
      *is_end_of_seq = 1;
      ch = getchar();
      goto end;
    }
    // If we get here, then we're not in a 27, 91, X sequence.
    ungetc(next, stdin);
  }

end:

  // Turn off non-blocking I/O. On some systems, leaving stdin
  // non-blocking will also leave stdout non-blocking, which can
  // cause printing errors.
  fcntl(STDIN_FILENO, F_SETFL, flags);
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
  system("tput setab 0");    // Use a black background.
  system("tput clear");      // Clear the screen.
  system("tput civis");      // Hide the cursor.
  system("stty raw -echo");  // Improve access to keypresses.
}

void done(const char *msg) {

  // Put the terminal back into a decent state.
  system("stty cooked echo");  // Undo init call to "stty raw".
  system("tput reset");        // Reset colors and clear screen.

  // Print the farewell message if there is one.
  if (msg) printf("%s\n", msg);

  exit(0);
}

void push_keypress(lua_State *L, int key, int is_end_of_seq) {
  if (is_end_of_seq && 65 <= key && key <= 68) {
    // up, down, right, left = 65, 66, 67, 68
    static const char *arrow_names[] = {"up", "down",
                                        "right", "left"};
    lua_pushstring(L, arrow_names[key - 65]);
  } else {
    lua_pushnumber(L, key);
  }
}

void push_state_table(lua_State *L,
                      int key,
                      int is_end_of_seq) {

  lua_newtable(L);

    // stack = [.., {}]

  push_keypress(L, key, is_end_of_seq);

    // stack = [.., {}, key]

  lua_setfield(L, -2, "key");

    // stack = [.., {key = key}]

  lua_pushnumber(L, gettime());

    // stack = [.., {key = key}, clock]

  lua_setfield(L, -2, "clock");

    // stack = [.., {key = key, clock = clock}]
}


// Lua-visible functions.

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

  // Set up API functions written in C.
  lua_register(L, "timestamp", timestamp);
  luaopen_Pair(L);
  lua_setglobal(L, "Pair");

  // Set up API functions written in Lua.
  luaL_dofile(L, "util.lua");
  luaL_dofile(L, "Character.lua");
  lua_setglobal(L, "Character");

  // Load eatyguy9 and run the init() function.
  luaL_dofile(L, "eatyguy9.lua");
  lua_setglobal(L, "eatyguy");
  lua_settop(L, 0);

  lua_getglobal(L, "eatyguy");
  lua_getfield(L, -1, "init");  // -1 means stack top.
  lua_call(L, 0, 0);            // 0, 0 = #args, #retvals

  lua_getglobal(L, "eatyguy");
  while (1) {
    int is_end_of_seq;
    int key = getkey(&is_end_of_seq);

    // Pass NULL to done() to print no ending message.
    if (key == ESC_KEY || key == 'q' || key == 'Q') done(NULL);

    // Call eatyguy.loop(state).
    lua_getfield(L, -1, "loop");
    push_state_table(L, key, is_end_of_seq);
    lua_call(L, 1, 1);

    // Check to see if the game is over.
    if (lua_isstring(L, -1)) {
      const char *msg = lua_tostring(L, -1);
      done(msg);
    }

    // Pop the return value of eatyguy.loop() off the stack.
    lua_pop(L, 1);

    sleephires(0.016);  // Sleep for 16ms.
  }

  return 0;
}
