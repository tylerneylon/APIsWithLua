#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

/*
char *file_contents(char *fname) {
  FILE *f = fopen(fname, "rb");
  fseek(f, 0, SEEK_END);
  long fsize = ftell(f);
  rewind(f);
  char *contents = malloc(fsize + 1);
  size_t bytes_read = fread(contents, 1, fsize, f);
  assert(bytes_read == fsize);
  contents[fsize] = '\0';
  fclose(f);
  return contents;
}
*/

lua_State *init() {
  system("stty raw");
  fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL) | O_NONBLOCK);

  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  luaL_dofile(L, "script1.lua");
  // The Lua stack now has the return values from the script.
  lua_setglobal(L, "script1");
  lua_settop(L, 0);  // Clear the stack.



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
