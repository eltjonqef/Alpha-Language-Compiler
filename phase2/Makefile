parser: parser.y
	bison --yacc --defines --output=parser.cpp parser.y

scanner: scanner.l
	flex --outfile=scanner.cpp scanner.l

all: scanner.cpp parser.cpp
	g++ scanner.cpp parser.cpp
