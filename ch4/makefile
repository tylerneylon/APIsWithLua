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

eatyguys = eatyguy6 eatyguy7 eatyguy8

obj_files = Pair.o mymodule.o

so_files = Pair.$(so_ext) mymodule.$(so_ext)

all = $(eatyguys) $(obj_files) $(so_files)

cc = cc -std=c99

all: $(all)

clean:
	rm -f $(all) *.o

$(eatyguys) : % : %.c $(lua_lib) Pair.o
	$(cc) $^ -o $@ $(flags)

$(obj_files) : %.o : %.c %.h
	$(cc) -c $< -o $@ $(cflags)

$(so_files) : %.$(so_ext) : $(so_dep)
	$(cc) $< -o $@ $(so_flags)

../lua/liblua.a:
	make -C ../lua liblua.a $(lua_flags)
