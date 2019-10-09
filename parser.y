%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "include.h"
/* prototypes */
nodeType *opr(int oper, int nops, ...);
nodeType *id(int i, char ch);
nodeType *con(int value);
void freeNode(nodeType *p);
int ex(nodeType *p);
int yylex(void);
void yyerror(char *s);
// int sym[26]; /* symbol table */
conNodeType sym[26];

%}
%union {
 int iValue; /* integer value */
 char sIndex; /* symbol table index */
 nodeType *nPtr; /* node pointer */
};

%token BOOLEAN INT
%token <iValue> INTEGER
%token <sIndex> VARIABLE
%token WHILE IF PRINT ASSGN
%nonassoc IFX
%nonassoc ELSE
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS
%type <nPtr> stmt expr stmt_list

%%
program:
  function { exit(0); }
  ;
function:
  function stmt { ex($2); freeNode($2); }
  | /* NULL */
  ;
stmt:
  ';' { $$ = opr(';', 2, NULL, NULL); }
  | expr ';' { $$ = $1; }
  | PRINT expr ';' { $$ = opr(PRINT, 1, $2); }
  | VARIABLE '=' expr ';' { $$ = opr('=', 2, id($1, 'o'), $3); }
  | INT VARIABLE '=' expr ';' { $$ = opr( INT, 2, id($2, 'i'), $4); }
  | BOOLEAN VARIABLE '=' expr ';' { $$ = opr( BOOLEAN, 2, id($2, 'b'), $4); }
  | WHILE '(' expr ')' stmt { $$ = opr(WHILE, 2, $3, $5); }
  | IF '(' expr ')' stmt %prec IFX { $$ = opr(IF, 2, $3, $5); }
  | IF '(' expr ')' stmt ELSE stmt
  { $$ = opr(IF, 3, $3, $5, $7); }
  | '{' stmt_list '}' { $$ = $2; }
  ;
stmt_list:
  stmt { $$ = $1; }
  | stmt_list stmt { $$ = opr(';', 2, $1, $2); }
  ;
expr:
  INTEGER { $$ = con($1); }
  | VARIABLE { $$ = id($1, 'o'); }
  | '-' expr %prec UMINUS { $$ = opr(UMINUS, 1, $2); }
  | expr '+' expr { $$ = opr('+', 2, $1, $3); }
  | expr '-' expr { $$ = opr('-', 2, $1, $3); }
  | expr '*' expr { $$ = opr('*', 2, $1, $3); }
  | expr '/' expr { $$ = opr('/', 2, $1, $3); }
  | expr '<' expr { $$ = opr('<', 2, $1, $3); }
  | expr '>' expr { $$ = opr('>', 2, $1, $3); }
  | expr GE expr { $$ = opr(GE, 2, $1, $3); }
  | expr LE expr { $$ = opr(LE, 2, $1, $3); }
  | expr NE expr { $$ = opr(NE, 2, $1, $3); }
  | expr EQ expr { $$ = opr(EQ, 2, $1, $3); }
  | '(' expr ')' { $$ = $2; }
  ;

%%
#define SIZEOF_NODETYPE ((char *)&p->con - (char *)p)
nodeType *con(int value) {
  nodeType *p;
  /* allocate node */
  if ((p = (nodeType*)malloc(sizeof(nodeType))) == NULL)
  yyerror("out of memory");
  /* copy information */
  p->type = typeCon;
  p->con.value = value;
  return p;
}

nodeType *id(int i, char ch) {
  nodeType *p;
  /* allocate node */
  if ((p = (nodeType*)malloc(sizeof(nodeType))) == NULL)
  yyerror("out of memory");
  /* copy information */
  p->type = typeId;
  p->id.i = i;
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
