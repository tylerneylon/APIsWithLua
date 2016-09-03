binaries = eatyguy6 eatyguy7 eatyguy8
other = Pair.$(soext)
include ../makefile_setup

# TODO Modify the Pair.a build step to work on Windows and Linux.

ifeq ($(OS),Windows_NT)
	# Windows.
	Pair_compile = $(cc) -c Pair.c -o Pair.o && $(cc) -shared Pair.o -o Pair.dll -llua
else
	# Non-windows.
	Pair_compile = $(cc) Pair.c -o Pair.so $(soflags)
endif

Pair.$(soext): Pair.c Pair.h
	$(Pair_compile)
