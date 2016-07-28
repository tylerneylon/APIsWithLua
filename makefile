all: eatyguy

clean:
	rm eatyguy

eatyguy: eatyguy.c clua.c
	cc $^ -o $@ -llua -L.
