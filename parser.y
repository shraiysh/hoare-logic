%{
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <stdarg.h>
#include "include.h"

/* prototypes */
nodeType *opr(int oper, int nops, ...);
nodeType *id(int i, char ch);
nodeType *arrId(int i, int j, char ch);
nodeType *con(int value,char ch);
void freeNode(nodeType *p);
// int ex(nodeType *p);
void add(nodeType *p);
void execute();
int ex(nodeType *p);
void updateSize(int index, int size);
int yylex(void);
void yyerror(char *s);
char dtype[26] = {0};

%}
%union {
 int iValue; /* integer value */
 char sIndex; /* symbol table index */
 nodeType *nPtr; /* node pointer */
};

%token BOOLEAN INT PRE POST TRUE FALSE ARR_VAR
%token <iValue> INTEGER
%token <sIndex> VARIABLE
%token WHILE IF PRINT ASSGN FORALL EXISTS INV
%nonassoc IFX
%nonassoc ELSE
%left NOT AND OR
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
%type <nPtr> stmt expr stmt_list pre_cond post_cond

%%
program:
  pre_cond function post_cond {execute(); exit(0); }
  ;

pre_cond:
  PRE stmt { $$ = opr(PRE,1,$2); add($$);}
  ;

post_cond:
  POST stmt { $$ = opr(POST,1,$2); add($$);}
  ;

function:
  function stmt { add($2); }
  | /* NULL */
  ;
stmt:
  ';' { $$ = opr(';', 2, NULL, NULL); }
  | expr ';' { $$ = $1; }
  | PRINT expr ';' { $$ = opr(PRINT, 1, $2); }
  | VARIABLE '=' expr ';' { $$ = opr('=', 2, id($1, 'o'), $3); }
  | VARIABLE '[' expr ']' '=' expr ';' { $$ = opr('=', 2, arrId($1, ex($3), 'o'), $6); }
  | INT VARIABLE ';' { dtype[$2] = 'i'; $$ = opr( INT, 1, id($2, 'i')); }
  | INT VARIABLE '[' expr ']' ';' { std::cout << "Hello" << ex($4) << "\n"; updateSize($2, ex($4)); /*$$ = opr(ARR_VAR, 1, arrId($2, ex($4), 'i'));*/}
  | BOOLEAN VARIABLE ';' { dtype[$2] = 'b'; $$ = opr( BOOLEAN, 1, id($2, 'b'));  }
  | INV stmt WHILE '(' expr ')' stmt { $$ = opr(WHILE, 3, $5, $2,$7); }
  | IF '(' expr ')' stmt %prec IFX { $$ = opr(IF, 2, $3, $5); }
  | IF '(' expr ')' stmt ELSE stmt
  { $$ = opr(IF, 3, $3, $5, $7); }
  | '{' stmt_list '}' { $$ = $2; }
  | FORALL VARIABLE '.' stmt {$$ = opr( FORALL, 2, id($2, 'o'), $4);}
  | EXISTS VARIABLE '.' stmt {$$ = opr( EXISTS, 2, id($2, 'o'), $4);}
  ;
stmt_list:
  stmt { $$ = $1; }
  | stmt_list stmt { $$ = opr(';', 2, $1, $2); }
  ;
expr:
  INTEGER { $$ = con($1,'i'); }
  | FALSE { $$ = con(0,'b'); }
  | TRUE { $$ = con(1,'b'); }
  | VARIABLE { $$ = id($1, 'o'); }
  | VARIABLE '[' expr ']' { $$ = arrId($1, ex($3), 'o'); }
  | '-' expr %prec UMINUS { $$ = opr(UMINUS, 1, $2); }
  | expr '+' expr { $$ = opr('+', 2, $1, $3); }
  | expr '-' expr { $$ = opr('-', 2, $1, $3); }
  | expr '*' expr { $$ = opr('*', 2, $1, $3); }
  | expr '/' expr { $$ = opr('/', 2, $1, $3); }
  | expr '%' expr { $$ = opr('%', 2, $1, $3); }
  | expr '<' expr { $$ = opr('<', 2, $1, $3); }
  | expr '>' expr { $$ = opr('>', 2, $1, $3); }
  | expr GE expr { $$ = opr(GE, 2, $1, $3); }
  | expr LE expr { $$ = opr(LE, 2, $1, $3); }
  | expr NE expr { $$ = opr(NE, 2, $1, $3); }
  | expr EQ expr { $$ = opr(EQ, 2, $1, $3); }
  | expr AND expr {$$ = opr(AND, 2, $1, $3); }
  | expr OR expr { $$ = opr(OR, 2, $1, $3); }
  | NOT expr { $$ = opr(NOT, 1, $2); }
  | '(' expr ')' { $$ = $2; }
  ;

%%
#define SIZEOF_NODETYPE ((char *)&p->con - (char *)p)
nodeType *con(int value,char ch) {
  nodeType *p;
  /* allocate node */
  if ((p = (nodeType*)malloc(sizeof(nodeType))) == NULL)
  yyerror("out of memory");
  /* copy information */
  p->type = typeCon;
  p->con.value = value; 
  p->con.dtype = ch;
  return p;
}

nodeType* id(int i, char ch) {
  return arrId(i, 0, ch);
}

nodeType *arrId(int i, int j, char ch) {
  nodeType *p;
  /* allocate node */
  if ((p = (nodeType*)malloc(sizeof(nodeType))) == NULL)
  yyerror("out of memory");
  /* copy information */
  p->type = typeId;
  p->id.i = i;
  p->id.j = j;
  p->id.dtype = ch;
  return p;
}

nodeType *opr(int oper, int nops, ...) {
  va_list ap;
  nodeType *p;
  int i;
  /* allocate node */
  if ((p = (nodeType*)malloc(sizeof(nodeType))) == NULL)
  yyerror("out of memory");
  if ((p->opr.op = (nodeTypeTag**)malloc(nops * sizeof(nodeType))) == NULL)
  yyerror("out of memory");
  /* copy information */
  p->type = typeOpr;
  p->opr.oper = oper;
  p->opr.nops = nops;
  va_start(ap, nops);
  for (i = 0; i < nops; i++)
  p->opr.op[i] = va_arg(ap, nodeType*);
  va_end(ap);
  return p;
}
void freeNode(nodeType *p) {
  int i;
  if (!p) return;
  if (p->type == typeOpr) {
  for (i = 0; i < p->opr.nops; i++)
  freeNode(p->opr.op[i]);
  free(p->opr.op);
  }
  free (p);
}
void yyerror(char *s) {
  fprintf(stdout, "%s\n", s);
}
int main(void) {
  yyparse();
  return 0;
} 
