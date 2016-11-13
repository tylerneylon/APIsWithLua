# Chapter 4 makefile.
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
	soflags      = -shared -llua
	so_dep       = %.o
	so_make      = $(cc) $< -o $@ $(soflags)
else ifeq ($(shell uname),Darwin)
	# macOS.
	cflags       = -I../lua
	flags        = -llua -L../lua $(cflags)
	lualib       = ../lua/liblua.a
	luaflags     = SYSCFLAGS="-DLUA_USE_MACOSX"
	soext        = so
	soflags      = -undefined dynamic_lookup -I../lua
	so_dep       = %.c %.h
	so_make      = $(cc) $< -o $@ $(soflags)
else
	# Guess Linux.
	cflags       = -D_POSIX_C_SOURCE=199309L -I../lua
	flags        = -llua -L../lua -lm -ldl $(cflags)
	lualib       = ../lua/liblua.a
	luaflags     = SYSCFLAGS="-DLUA_USE_LINUX"
	soext        = so
	soflags      = -I../lua -shared -fpic
	so_dep       = %.c %.h
	so_make      = $(cc) $< -o $@ $(soflags)
	pair_so_make = Pair.c -o Pair.so $(soflags)
	mm_make      = cc -std=c99 mymodule.c -o mymodule.so $(soflags)
endif

eatyguys = eatyguy6 eatyguy7 eatyguy8

obj_files = Pair.o mymodule.o

so_files = Pair.$(soext) mymodule.$(soext)

all = $(eatyguys) $(obj_files) $(so_files)

cc = cc -std=c99

all: $(all)

clean:
	rm -f $(all) *.o

$(eatyguys) : % : %.c $(lualib) Pair.o
	$(cc) $^ -o $@ $(flags)

$(obj_files) : %.o : %.c %.h
	$(cc) -c $< -o $@ $(cflags)

$(so_files) : %.$(soext) : $(so_dep)
	$(so_make)

../lua/liblua.a:
	make -C ../lua liblua.a $(luaflags)
