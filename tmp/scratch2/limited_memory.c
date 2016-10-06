// limited_memory.c
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>
#include <stdlib.h>

// TODO Actually limit memory.
//      For now I'm just starting with a
//      simple interpreter.

void *alloc(void *ud,
            void *ptr,
            size_t osize,
            size_t nsize) {
  printf("alloc(%p, %zd, %zd)\n", ptr, osize, nsize);
  if (nsize) return realloc(ptr, nsize);
  free(ptr);
  return NULL;
}

int main() {
  lua_State *L = lua_newstate(alloc, NULL);
  luaL_openlibs(L);

  char buff[2048];
  while (fgets(buff, sizeof(buff), stdin)) {
    int error = luaL_loadstring(L, buff);
    if (!error) error = lua_pcall(L, 0, 0, 0);
    if (error) {
      fprintf(stderr, "%s\n", lua_tostring(L, -1));
      lua_pop(L, 1);
    }
  }

  lua_close(L);
  return 0;
}
