#include <stdio.h>
#include "include.h"
#include "y.tab.h"
conNodeType ex(nodeType *p) {
  conNodeType res = {0, 'o'};
  if (!p) return res;
  switch(p->type) {
    case typeCon:
      res = p->con;
      return res;

    case typeId: 
      return sym[p->id.i];

    case typeOpr:
      switch(p->opr.oper) {
        case WHILE:
          while(ex(p->opr.op[0]).value)
            ex(p->opr.op[1]);
          return res;

        case IF: 
          if (ex(p->opr.op[0]).value)
            ex(p->opr.op[1]);
          else if (p->opr.nops > 2)
            ex(p->opr.op[2]);
          return res;

        case PRINT:
          printf("%d, %c\n", ex(p->opr.op[0]).value, ex(p->opr.op[0]).dtype);
          return res;

        case INT:
          sym[p->opr.op[0]->id.i] = {ex(p->opr.op[1]).value, 'i'};
          return sym[p->opr.op[0]->id.i];

        case BOOLEAN:
          sym[p->opr.op[0]->id.i] = {ex(p->opr.op[1]).value, 'b'};
          return sym[p->opr.op[0]->id.i];

        case ';': ex(p->opr.op[0]); return ex(p->opr.op[1]);

        case UMINUS:
          res = {-ex(p->opr.op[0]).value, 'i'};
          return res;

        case '=':
          conNodeType rhs = ex(p->opr.op[1]);
          char prevType = sym[p->opr.op[0]->id.i].dtype;
          
          if((prevType == 'i' || prevType == 'b') && prevType != rhs.dtype) {
            printf("[interpreter.c] :: Types are not matching!! %c = %c\n", prevType, rhs.dtype);
          }

          sym[p->opr.op[0]->id.i] = { rhs.value, rhs.dtype };
          return sym[p->opr.op[0]->id.i];
      }

      // If not till here, it is a binary operator
      conNodeType a = ex(p->opr.op[0]), b = ex(p->opr.op[1]);
      switch(p->opr.oper) {

        case '+':
          // This check is not necessarily needed,
          //but in case we need it, we can replicate and put some error handling mechanism
          if(a.dtype == 'b' || b.dtype == 'b') {
            printf("Addition on bools!\n");
          }
          res = {a.value + b.value, 'i'};
          return res;

        case '-': 
          res = {a.value - b.value, 'i'};
          return res;

        case '*':
          res = {a.value * b.value, 'i'};
          return res;
        case '/':
          res = {a.value / b.value, 'i'};
          return res;
        case '<': 
          res = {a.value < b.value, 'b'};
          return res;
        case '>':
          res = {a.value > b.value, 'b'};
          return res;
        case GE:
          res = {a.value >= b.value, 'b'};
          return res;
        case LE:
          res = {a.value <= b.value, 'b'};
          return res;
        case NE:
          res = {a.value != b.value, 'b'};
          return res;
        case EQ:
          res = {a.value == b.value, 'b'};
          return res;
      }
  }
  return res;
} 
