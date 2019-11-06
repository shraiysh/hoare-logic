%{
#include <stdlib.h>
#include "include.h"
#include "y.tab.h"
void yyerror(char *);
%}

%%

"int" return INT;
"bool" return BOOLEAN;
"pre" return PRE;
"post" return POST;
"true" return TRUE;
"false" return FALSE;
"&&" return AND;
"||" return OR;
"~" return NOT;
"@" return FORALL;
"#" return EXISTS;
"inv" return INV;

[a-z] {
  yylval.sIndex = *yytext - 'a';
  return VARIABLE;
  }

[A-Z] {
  yylval.sIndex = *yytext - 'A';
  return ARR_VAR;
  }

0 {
  yylval.iValue = atoi(yytext);
  return INTEGER;
  }
  
[1-9][0-9]* {
  yylval.iValue = atoi(yytext);
  return INTEGER;
  }
[-()<>=+*/%;{}.] {
  return *yytext;
  }

"[" return *yytext;
"]" return *yytext;
">=" return GE;
"<=" return LE;
"==" return EQ;
"!=" return NE;
"while" return WHILE;
"if" return IF;
"else" return ELSE;
"print" return PRINT;

[ \t\n]+ ; /* ignore whitespace */

. yyerror("Unknown character");
%%

int yywrap(void) {
 return 1;
} 
