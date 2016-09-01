binaries = eatyguy6 eatyguy7 eatyguy8
other = Pair.so
include ../makefile_setup

# TODO Modify the Pair.a build step to work on Windows and Linux.

Pair.so: Pair.c Pair.h
	cc Pair.c -undefined dynamic_lookup -o Pair.so -I../lua
