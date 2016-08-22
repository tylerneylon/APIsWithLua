binaries = eatyguy1
flags    = -llua -Llua -Ilua

all: $(binaries)

clean:
	rm $(binaries)

$(binaries) : % : %.c
	cc $< -o $@ $(flags)
