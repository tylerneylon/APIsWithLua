ifeq ($(OS),Windows_NT)
  flags = -llua
	bin   = eatyguy.exe
else
  flags = -llua -Llua -Ilua
	bin   = eatyguy
endif

all: eatyguy

clean:
	rm $(bin)

eatyguy: eatyguy.c util.c
	cc $^ -o $@ $(flags)
