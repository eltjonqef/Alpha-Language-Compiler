parser: parser.y
	bison --yacc --defines --output=parser.cpp parser.y

scanner: scanner.l
	flex --outfile=scanner.cpp scanner.l

all: parser.y scanner.l
	bison --yacc --defines --output=parser.cpp parser.y
	flex --outfile=scanner.cpp scanner.l
	g++ -o parser scanner.cpp parser.cpp

clean:
	rm -f parser parser.cpp parser.hpp scanner.cpp scanner.h