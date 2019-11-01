all:
	lex lexer.l
	yacc -d -t parser.y
	g++ lex.yy.c y.tab.c -g -w interpreter.cpp -lz3

clean:
	rm -rf a.out lex.yy.c y.tab.c y.tab.h 