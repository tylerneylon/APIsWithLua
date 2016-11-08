// limit_cpu.c
//

#include "interpreter.h"

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>
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

void print_status() {
  printf("%ld instructions run so far\n", instruction_count);
}

int main() {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_sethook(L, hook, LUA_MASKCOUNT, instructions_per_hook);

  print_status();
  while (accept_and_run_a_line(L)) print_status();

  lua_close(L);
  return 0;
}
