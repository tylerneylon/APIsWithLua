binaries = eatyguy1 eatyguy2 eatyguy3

ifeq ($(OS),Windows_NT)
	# Windows.
	flags    = -llua
else ifeq ($(shell uname),Darwin)
	# macOS.
	flags    = -llua -L../lua -I../lua
	lualib   = ../lua/liblua.a
	luaflags = SYSCFLAGS="-DLUA_USE_MACOSX"
else
	# Guess Linux.
	flags    = -llua -L../lua -I../lua -lm -ldl
	lualib   = ../lua/liblua.a
	luaflags = SYSCFLAGS="-DLUA_USE_LINUX"
endif

all: $(binaries)

clean:
	rm -f $(binaries)

$(binaries) : % : %.c $(lualib)
	cc $< -o $@ $(flags)

../lua/liblua.a:
	make -C ../lua liblua.a $(luaflags)
