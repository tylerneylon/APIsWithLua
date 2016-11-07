// limit_memory.c
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/errno.h>

long bytes_alloced = 0;
long max_bytes = 30000;

void *alloc(void *ud,
            void *ptr,
            size_t osize,
            size_t nsize) {

  // Compute the byte change requested. May be negative.
  long num_bytes_to_add = nsize - (ptr ? osize : 0);

  // Reject the change if it would exceed our limit.
  if (bytes_alloced + num_bytes_to_add > max_bytes) {
    errno = ENOMEM;
    return NULL;
  }

  // Otherwise, free or allocate memory as requested.
  bytes_alloced += num_bytes_to_add;
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
