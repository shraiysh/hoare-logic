%{
#include <stdlib.h>
#include "include.h"
#include "y.tab.h"
void yyerror(char *);
%}

%%

[a-z] {
  yylval.sIndex = *yytext - 'a';
  return VARIABLE;
  }
0 {
  yylval.iValue = atoi(yytext);
  return INTEGER;
  }
[1-9][0-9]* {
  yylval.iValue = atoi(yytext);
  return INTEGER;
  }
[-()<>=+*/;{}.] {
  return *yytext;
  }

">=" return GE;
"<=" return LE;
"==" return EQ;
"!=" return NE;
"while" return WHILE;
"if" return IF;
"else" return ELSE;
"print" return PRINT;
"&&" return AND;
"||" return OR;
"~" return NOT;

[ \t\n]+ ; /* ignore whitespace */

. yyerror("Unknown character");
%%

int yywrap(void) {
 return 1;
} 
