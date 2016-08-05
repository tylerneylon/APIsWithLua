#pragma once

#include "lua.h"

void call(lua_State *L, const char *mod,
          const char *fn, const char *types, ...);

double gettime();
int    getkey();
void   tinysleep(double sec);
