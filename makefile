# This makefile will build all the binaries and libraries in this repo.
# The built products will be in the same directory as their source.
#
# The code for each chapter can also be compiled on a per-chapter basis using
# the makefile in the directory of that chapter.
#

subdirs = ch1 ch2 ch3 ch4 ch5 ch6

all:
	for dir in $(subdirs); do make -C $$dir; done
	#
	# Built products are in the chapter directories (ch1, ch2, etc.)
	#

clean:
	for dir in $(subdirs); do make -C $$dir clean; done
