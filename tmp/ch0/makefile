all: eatyguy

clean:
	rm eatyguy

eatyguy: eatyguy.c util.c
	cc $^ -o $@ -llua -L.
