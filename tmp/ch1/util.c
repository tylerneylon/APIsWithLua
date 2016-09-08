#include "util.h"

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

#include "lauxlib.h"

int getkey() {

  // We care about two cases:
  // Case 1: A sequence of the form 27, 91, X; return X.
  // Case 2: For any other sequence, return each int separately.

  int ch = getchar();
  if (ch == 27) {
    int next = getchar();
    if (next == 91) return getchar();
    // If we get here, then we're not in a 27, 91, X sequence.
    ungetc(next, stdin);
  }
  return ch;
}

double gettime() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_sec + 1e-6 * tv.tv_usec;
}

void tinysleep(double sec) {
  long s = (long)floor(sec);
  long n = (long)floor((sec - s) * 1e9);
  struct timespec delay = { .tv_sec = s, .tv_nsec = n };
  nanosleep(&delay, NULL);
}

// Most of this function is from a similar function in the book Programming in
// Lua by Roberto Ierusalimschy, 3rd edition.
void call(lua_State *L, const char *mod, const char *fn,
          const char *types, ...) {
  
  va_list args;
  va_start(args, types);

  lua_getglobal(L, mod);
  
  if (lua_isnil(L, -1)) {
    printf("call: module '%s' is nil (not loaded)\n", mod);
    lua_pop(L, 1);
    return;
  }
  
  lua_getfield(L, -1, fn);
  lua_remove(L, -2);
  
  // Parse types of and push input arguments.
  int nargs;
  for (nargs = 0; *types; ++nargs) {
    luaL_checkstack(L, 1, "too many arguments in call");
    switch (*types++) {
      case 'd':  // double
        lua_pushnumber(L, va_arg(args, double));
        break;
        
      case 'i':  // int
        lua_pushinteger(L, va_arg(args, int));
        break;
        
      case 's':  // string
        lua_pushstring(L, va_arg(args, char *));
        break;
        
      case 'b': // boolean
        lua_pushboolean(L, va_arg(args, int));
        break;
        
      case '>':
        goto endargs;
        
      default:
        printf("call: Unrecognized type character.\n");
    }
  }
  
endargs:;  // Semi-colon here as an empty statement so we can declare nresults.
  
  int nresults = (int)strlen(types);
  int results_left = nresults;
  int error = lua_pcall(L, nargs, nresults, 0);
  if (error) {
    printf("Error in call to %s.%s:", mod, fn);
    printf("%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
  }
  const char *type_err_fmt =
      "call type error: bad result type - expected type %s\n";
  
  while (*types) {
    switch (*types++) {
      case 'd': {
        if (!lua_isnumber(L, -results_left)) {
          printf(type_err_fmt, "d");
          goto alldone;
        }
        *va_arg(args, double *) = lua_tonumber(L, -results_left);
        break;
      }
        
      case 'i': {
        if (!lua_isnumber(L, -results_left)) {
          printf(type_err_fmt, "i");
          goto alldone;
        }
        *va_arg(args, int *) = (int)lua_tointeger(L, -results_left);
        break;
      }
        
      case 'b': {
        if (!lua_isboolean(L, -results_left)) {
          printf(type_err_fmt, "b");
          goto alldone;
        }
        *va_arg(args, int *) = (int)lua_toboolean(L, -results_left);
        break;
      }
        
      case 's': {
        const char *s = lua_tostring(L, -results_left);
        if (s == NULL) {
          printf(type_err_fmt, "s");
          goto alldone;
        }
        *va_arg(args, char **) = s ? strdup(s) : NULL;
        break;
      }
        
      default:
        printf("call: Unrecognized type character.\n");
    }
    results_left--;
  }
  
alldone:;
  lua_pop(L, nresults);
  va_end(args);
}

