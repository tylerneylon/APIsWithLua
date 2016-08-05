binaries = doscript loadmodule runmodule
flags    = -llua -Llua -Ilua

all: $(binaries)

clean:
	rm $(binaries)

$(binaries) : % : %.c
	cc $< -o $@ $(flags)
