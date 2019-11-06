all:
	lex lexer.l
	yacc -d parser.y
	g++ lex.yy.c y.tab.c -w -g interpreter.cpp -lz3

clean:
	rm -rf a.out lex.yy.c y.tab.c y.tab.h 