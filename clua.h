// clua.h
//
// A module to help integrate C and embedded Lua.
//

#pragma once

#include "lua.h"

void call(lua_State *L, const char *mod,
          const char *fn, const char *types, ...);
