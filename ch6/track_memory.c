// track_memory.c
//

#include "interpreter.h"

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

void print_status() {
  printf("%ld bytes allocated\n", bytes_alloced);
}

int main() {
  lua_State *L = lua_newstate(alloc, NULL);
  luaL_openlibs(L);

  print_status();
  while (accept_and_run_a_line(L)) print_status();

  lua_close(L);
  print_status();
  return 0;
}
