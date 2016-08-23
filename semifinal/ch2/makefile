binaries = eatyguy1 eatyguy2

ifeq ($(OS),Windows_NT)
  flags = -llua
else
  flags = -llua -Llua -Ilua
endif

all: $(binaries)

clean:
	rm -f $(binaries)

$(binaries) : % : %.c
	cc $< -o $@ $(flags)
