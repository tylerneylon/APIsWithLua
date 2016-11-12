# TODO Update this makefile.
# For now it is a slightly modified copy of the one from chapter 4.
#
# To build all the binaries for this chapter, simply run:
# $ make
#
# To remove the build products, including binaries, run:
# $ make clean
#  

# Platform-specific settings.
ifeq ($(OS),Windows_NT)
	# Windows.
	flags        = -llua
	soext        = dll
	pair_so_make = -shared Pair.o -o Pair.dll -llua
	pair_so_dep  = Pair.o
	mm_make      = cc -std=c99 -c mymodule.c -o mymodule.o && cc -shared mymodule.o -o mymodule.dll -llua
else ifeq ($(shell uname),Darwin)
	# macOS.
	cflags       = -I../lua
	flags        = -llua -L../lua $(cflags)
	lualib       = ../lua/liblua.a
	luaflags     = SYSCFLAGS="-DLUA_USE_MACOSX"
	soext        = so
	soflags      = -undefined dynamic_lookup -I../lua
	pair_so_make = Pair.c -o Pair.so $(soflags)
	mm_make      = cc -std=c99 mymodule.c -o mymodule.so $(soflags)
else
	# Guess Linux.
	cflags       = -D_POSIX_C_SOURCE=199309L -I../lua
	flags        = -llua -L../lua -lm -ldl $(cflags)
	lualib       = ../lua/liblua.a
	luaflags     = SYSCFLAGS="-DLUA_USE_LINUX"
	soext        = so
	soflags      = -I../lua -shared -fpic
	pair_so_make = Pair.c -o Pair.so $(soflags)
	mm_make      = cc -std=c99 mymodule.c -o mymodule.so $(soflags)
endif

interpreters = track_memory limit_memory limit_cpu

binaries = eatyguy10 library_subset $(interpreters)

obj_files = Pair.o interpreter.o

cc = cc -std=c99

all: $(binaries)

clean:
	rm -f $(binaries) *.o

eatyguy10: eatyguy10.c $(lualib) Pair.o
	$(cc) $^ -o $@ $(flags)

$(interpreters) : % : %.c $(lualib) interpreter.o
	$(cc) $^ -o $@ $(flags)

$(obj_files) : %.o : %.c %.h
	$(cc) -c $< -o $@ $(cflags)

library_subset: library_subset.c $(lualib)
	$(cc) $< -o $@ $(flags)

../lua/liblua.a:
	make -C ../lua liblua.a $(luaflags)
