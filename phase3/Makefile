all: parser.y scanner.l
	bison -v --yacc --defines --output=parser.cpp parser.y
	flex --outfile=scanner.cpp scanner.l
	g++ -std=c++11 -o parser scanner.cpp parser.cpp

clean:
	rm -f parser parser.cpp parser.hpp parser.output scanner.cpp scanner.h