// interpreter.h
//

#include "lua.h"

// This returns 0 if the line indicated the end of input,
// usually given by pressing control-D; otherwise returns 1.
int accept_and_run_a_line(lua_State *L);
