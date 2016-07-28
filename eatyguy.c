#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

lua_State *init() {
  system("stty raw");
  fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL) | O_NONBLOCK);

  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  return L;
}

void done() {
  system("stty cooked");
  exit(0);
}

void loop(lua_State *L) {
  int ch = getchar();
  //printf("Got char code %d.\n", ch);
  if (ch == 32) done();
}

int main() {
  lua_State *L = init();
  while (1) loop(L);
  return 0;
}
