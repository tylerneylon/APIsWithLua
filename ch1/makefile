ifeq ($(OS),Windows_NT)
  flags = -llua
else
  flags = -llua -Llua
endif

all: eatyguy

clean:
	rm eatyguy

eatyguy: eatyguy.c util.c
	cc $^ -o $@ $(flags)
