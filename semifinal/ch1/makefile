binaries = doscript loadmodule runmodule

ifeq ($(OS),Windows_NT)
	flags  = -llua
	lualib = ""
else
	flags  = -llua -L../lua -I../lua
	lualib = ../lua/liblua.a
endif

all: $(binaries)

clean:
	rm -f $(binaries)

$(binaries) : % : %.c $(lualib)
	cc $< -o $@ $(flags)

../lua/liblua.a:
	make -C ../lua liblua.a

