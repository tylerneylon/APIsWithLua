all: eatyguy

eatyguy: eatyguy.c
	cc $< -o $@ -llua -L.
