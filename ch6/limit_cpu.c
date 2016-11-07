// limit_cpu.c
//

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/errno.h>

int do_limit_instructions    =    1;
long instructions_per_hook   =    1;  // 100+ recommended.
long instruction_count       =    0;
long instruction_count_limit =  100;

void hook(lua_State *L, lua_Debug *ar) {

  instruction_count += instructions_per_hook;

  if (!do_limit_instructions) return;

  if (instruction_count > instruction_count_limit) {
    lua_pushstring(L, "exceeded allowed cpu time");
    lua_error(L);
  }
}

char *line(char *buff, int size) {
  printf("%ld instructions executed\n", instruction_count);
  printf("> ");
  return fgets(buff, size, stdin);
}

int main() {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_sethook(L, hook, LUA_MASKCOUNT, instructions_per_hook);

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
  return 0;
}
