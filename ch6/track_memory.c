// track_memory.c
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>
#include <stdlib.h>

long bytes_alloced = 0;

void *alloc(void *ud,
            void *ptr,
            size_t osize,
            size_t nsize) {
  bytes_alloced += nsize - (ptr ? osize : 0);
  if (nsize) return realloc(ptr, nsize);
  free(ptr);
  return NULL;
}

char *line(char *buff, int size) {
  printf("%ld bytes allocated\n", bytes_alloced);
  printf("> ");
  return fgets(buff, size, stdin);
}

int main() {
  lua_State *L = lua_newstate(alloc, NULL);
  luaL_openlibs(L);

  char buff[2048];
  while (line(buff, sizeof(buff))) {
    int error = luaL_loadstring(L, buff);
    if (!error) error = lua_pcall(L, 0, 0, 0);
    if (error) {
      fprintf(stderr, "%s\n", lua_tostring(L, -1));
      lua_pop(L, 1);
    }
  }

  lua_close(L);
  printf("\n%ld bytes allocated\n", bytes_alloced);
  return 0;
}
