ifeq ($(OS),Windows_NT)
  flags    = -llua
	binaries = $(addsuffix .exe,doscript loadmodule runmodule)
else
  flags    = -llua -Llua -Ilua
	binaries = doscript loadmodule runmodule
endif

all: $(binaries)

clean:
	rm -f $(binaries)

$(binaries) : % : %.c
	cc $< -o $@ $(flags)
