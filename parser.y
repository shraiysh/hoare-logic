%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "include.h"

/* prototypes */
nodeType *opr(int lineno, int oper, int nops, ...);
nodeType *id(int i, char ch);
nodeType *con(int value,char ch);
void freeNode(nodeType *p);
// int ex(nodeType *p);
void add(nodeType *p);
void execute();
int yylex(void);
void yyerror(char *s);
char dtype[26] = {0};
int lineno=1;
%}
%union {
 int iValue; /* integer value */
 char sIndex; /* symbol table index */
 nodeType *nPtr; /* node pointer */
};

%token BOOLEAN INT PRE POST TRUE FALSE
%token <iValue> INTEGER
%token <sIndex> VARIABLE ARR_VAR
%token WHILE IF PRINT ASSGN FORALL EXISTS INV ARR_ACCESS ARR_ASSGN
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
  PRE stmt { $$ = opr(lineno,PRE,1,$2); add($$);}
  ;

post_cond:
  POST stmt { $$ = opr(lineno,POST,1,$2); add($$);}
  ;

function:
  function stmt { add($2); }
  | /* NULL */
  ;
stmt:
  ';' { $$ = opr(';', 2, NULL, NULL); }
  | expr ';' { $$ = $1; }
  | PRINT expr ';' { $$ = opr(lineno,PRINT, 1, $2); }
  | VARIABLE '=' expr ';' { $$ = opr(lineno,'=', 2, id($1, 'o'), $3);}
  | ARR_VAR '[' expr ']' '=' expr ';' { $$ = opr(lineno,ARR_ASSGN, 3, id($1, 'o'), $3, $6);}
  | INT VARIABLE ';' { $$ = opr(lineno, INT, 1, id($2, 'i')); dtype[$2] = 'i';}
  | BOOLEAN VARIABLE ';' { $$ = opr(lineno, BOOLEAN, 1, id($2, 'b')); dtype[$2] = 'b'; }
  | INV stmt WHILE '(' expr ')' stmt { $$ = opr(lineno, WHILE, 3, $5, $2,$7);}
  | IF '(' expr ')' stmt %prec IFX { $$ = opr(lineno, IF, 2, $3, $5);}
  | IF '(' expr ')' stmt ELSE stmt
  { $$ = opr(lineno, IF, 3, $3, $5, $7);}
  | '{' stmt_list '}' { $$ = $2; }
  
  ;
stmt_list:
  stmt { $$ = $1; }
  | stmt_list stmt { $$ = opr(lineno,';', 2, $1, $2); }
  ;
expr:
  INTEGER { $$ = con($1,'i'); }
  | FALSE { $$ = con(0,'b'); }
  | TRUE { $$ = con(1,'b'); }
  | VARIABLE { $$ = id($1, 'o'); }
  | ARR_VAR '[' expr ']' { $$ = opr(-1,ARR_ACCESS, 2, id($1, 'o'), $3); }
  | '-' expr %prec UMINUS { $$ = opr(-1,UMINUS, 1, $2); }
  | expr '+' expr { $$ = opr(-1,'+', 2, $1, $3); }
  | expr '-' expr { $$ = opr(-1,'-', 2, $1, $3); }
  | expr '*' expr { $$ = opr(-1,'*', 2, $1, $3); }
  | expr '/' expr { $$ = opr(-1,'/', 2, $1, $3); }
  | expr '%' expr { $$ = opr(-1,'%', 2, $1, $3); }
  | expr '<' expr { $$ = opr(-1,'<', 2, $1, $3); }
  | expr '>' expr { $$ = opr(-1,'>', 2, $1, $3); }
  | expr GE expr { $$ = opr(-1,GE, 2, $1, $3); }
  | expr LE expr { $$ = opr(-1,LE, 2, $1, $3); }
  | expr NE expr { $$ = opr(-1,NE, 2, $1, $3); }
  | expr EQ expr { $$ = opr(-1,EQ, 2, $1, $3); }
  | expr AND expr {$$ = opr(-1,AND, 2, $1, $3); }
  | expr OR expr { $$ = opr(-1,OR, 2, $1, $3); }
  | NOT expr { $$ = opr(-1,NOT, 1, $2); }
  | '(' expr ')' { $$ = $2; }
  | FORALL VARIABLE '(' expr ')' {$$ = opr(-1,FORALL, 2, id($2, 'o'), $4);}
  | EXISTS VARIABLE '(' expr ')' {$$ = opr(1,EXISTS, 2, id($2, 'o'), $4);}
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

nodeType *opr(int lineno, int oper, int nops, ...) {
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
  p->opr.lineno = lineno;
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
