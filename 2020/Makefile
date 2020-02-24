flex: scanner.l
	flex --outfile=scanner.c scanner.l

scanner: scanner.c
	g++ -o scanner scanner.c

all: scanner.l
	make flex
	make scanner
