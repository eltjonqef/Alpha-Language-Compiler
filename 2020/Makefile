flex: scanner.l
	flex --outfile=scanner.c scanner.l

scanner: scanner.c
	gcc -o scanner.c scanner

all: scanner.l scanner.c
	make flex
	make scanner
