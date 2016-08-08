binaries = eatyguy1 eatyguy2
flags    = -llua -Llua -Ilua

all: $(binaries)

clean:
	rm $(binaries)

$(binaries) : % : %.c
	cc $< -o $@ $(flags)
