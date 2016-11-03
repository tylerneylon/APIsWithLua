// test1.c
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

static int pairsmeta (lua_State *L, const char *method, int iszero,
                      lua_CFunction iter) {
  if (luaL_getmetafield(L, 1, method) == LUA_TNIL) {  /* no metamethod? */
    luaL_checktype(L, 1, LUA_TTABLE);  /* argument must be a table */
    lua_pushcfunction(L, iter);  /* will return generator, */
    lua_pushvalue(L, 1);  /* state, */
    if (iszero) lua_pushinteger(L, 0);  /* and initial value */
    else lua_pushnil(L);
  }
  else {
    lua_pushvalue(L, 1);  /* argument 'self' to metamethod */
    lua_call(L, 1, 3);  /* get 3 values from metamethod */
  }
  return 3;
}


static int luaB_next (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_settop(L, 2);  /* create a 2nd argument if there isn't one */
  if (lua_next(L, 1))
    return 2;
  else {
    lua_pushnil(L);
    return 1;
  }
}


static int luaB_pairs (lua_State *L) {
  return pairsmeta(L, "__pairs", 0, luaB_next);
}

int pr(lua_State *L) {
  int n = lua_gettop(L);
  for (int i = 1; i <= n; ++i) {
    if (i) printf(" ");
    printf("%s", lua_tostring(L, i));
  }
  printf("\n");
  return 0;
}

static const luaL_Reg my_base_funcs[] = {
  {"pairs", luaB_pairs},
  {"print", pr},
  {NULL, NULL}
};

int main() {
  lua_State *L = lua_newstate(alloc, NULL);
  lua_pushglobaltable(L);
  luaL_setfuncs(L, my_base_funcs, 0);  // 0 == number of upvalues
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "_G");
  lua_settop(L, 0);

  int do_set_global = 1;
  luaL_requiref(L, "_G", luaopen_base, do_set_global);
  luaL_requiref(L, "package", luaopen_package, do_set_global);
  //luaL_openlibs(L);

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

