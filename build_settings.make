# makefile_setup
#
# This makefile is meant to be included by chapter-specific
# makefiles within each ch* directory.
#
# Here are the meanings of some key variables:
#
# Variable   Meaning
# -----------------------------
#
# flags      standard C compilation flags
#
# lua_lib    name of Lua library file to build
#            (omitted on Windows as we assume it's prebuilt)
#
# lua_flags  platform-specific flags for building $(lualib)
#
# so_ext     filename extension for shared object files
#            (this is dll on windows, so on other systems)
#
# so_flags   cc flags specific to building so files
#            (Windows is a 2-step process; see ch4/makefile)
#

cc = cc -std=c99

# Platform-specific settings.
ifeq ($(OS),Windows_NT)
	# Windows.
	flags     = -llua
	so_ext    = dll
	so_flags  = -shared -llua
	so_dep    = %.o
	so_make   = $(cc) $< -o $@ $(so_flags)
else ifeq ($(shell uname),Darwin)
	# macOS.
	cflags    = -I../lua
	flags     = -llua -L../lua $(cflags)
	lua_lib   = ../lua/liblua.a
	lua_flags = SYSCFLAGS="-DLUA_USE_MACOSX"
	so_ext    = so
	so_flags  = -undefined dynamic_lookup -I../lua
	so_dep    = %.c %.h
	so_make   = $(cc) $< -o $@ $(so_flags)
else
	# Guess Linux.
	cflags    = -D_POSIX_C_SOURCE=199309L -I../lua
	flags     = -llua -L../lua -lm -ldl $(cflags)
	lua_lib   = ../lua/liblua.a
	lua_flags = SYSCFLAGS="-DLUA_USE_LINUX"
	so_ext    = so
	so_flags  = -I../lua -shared -fpic
	so_dep    = %.c %.h
	so_make   = $(cc) $< -o $@ $(so_flags)
endif

all = $(binaries) $(eatyguys) $(obj_files) $(so_files) $(interpreters)

all: $(all)

clean:
	rm -f $(all) *.o

$(binaries) : % : %.c $(lua_lib)
	$(cc) $< -o $@ $(flags)

$(eatyguys) : % : %.c $(lua_lib) Pair.o
	$(cc) $^ -o $@ $(flags)

$(interpreters) : % : %.c $(lua_lib) interpreter.o
	$(cc) $^ -o $@ $(flags)

$(obj_files) : %.o : %.c %.h
	$(cc) -c $< -o $@ $(cflags)

$(so_files) : %.$(so_ext) : $(so_dep)
	$(cc) $< -o $@ $(so_flags)

../lua/liblua.a:
	make -C ../lua liblua.a $(lua_flags)
