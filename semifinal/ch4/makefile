ifeq ($(OS),Windows_NT)
	# Windows.
	flags        = -llua
	soext        = dll
	pair_so_make = -shared Pair.o -o Pair.dll -llua
	pair_so_dep  = Pair.o
else ifeq ($(shell uname),Darwin)
	# macOS.
	cflags       = -I../lua
	flags        = -llua -L../lua $(cflags)
	lualib       = ../lua/liblua.a
	luaflags     = SYSCFLAGS="-DLUA_USE_MACOSX"
	soext        = so
	soflags      = -undefined dynamic_lookup -I../lua
	pair_so_make = Pair.c -o Pair.so $(soflags)
else
	# Guess Linux.
	cflags       = -D_POSIX_C_SOURCE=199309L -I../lua
	flags        = -llua -L../lua -lm -ldl $(cflags)
	lualib       = ../lua/liblua.a
	luaflags     = SYSCFLAGS="-DLUA_USE_LINUX"
	soext        = so
	soflags      = -I../lua -shared -fpic
	pair_so_make = Pair.c -o Pair.so $(soflags)
endif

files = eatyguy6 eatyguy7 eatyguy8 Pair.o Pair.$(soext)

cc = cc -std=c99

all = $(files)

all: $(all)

clean:
	rm -f $(all) *.o

eatyguy6: eatyguy6.c $(lualib)
	$(cc) $< -o $@ $(flags)

eatyguy7: eatyguy7.c $(lualib)
	$(cc) $< -o $@ $(flags)

eatyguy8: eatyguy8.c $(lualib) Pair.o
	$(cc) $< -o $@ $(flags) Pair.o

../lua/liblua.a:
	make -C ../lua liblua.a $(luaflags)

Pair.o: Pair.c Pair.h
	$(cc) -c $< -o $@ $(cflags)

Pair.$(soext): Pair.c Pair.h $(pair_so_dep)
	$(cc) $(pair_so_make)
