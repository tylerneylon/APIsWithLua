binaries = doscript loadmodule runmodule

ifeq ($(OS),Windows_NT)
  flags    = -llua
else
  flags    = -llua -L../lua -I../lua
endif

all: $(binaries)

clean:
	rm -f $(binaries)

$(binaries) : % : %.c
	cc $< -o $@ $(flags)
