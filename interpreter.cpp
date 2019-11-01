#include <stdio.h>
#include "include.h"
#include "y.tab.h"
#include <vector>
#include<algorithm>
#include <z3++.h>
using namespace z3;
std::vector<nodeType*> stmts;
std::vector<std::vector<expr>> sym(26);


context c;


void add(nodeType* p){
  stmts.push_back(p);
}


expr make_condition(nodeType *p){
  if(p == NULL) return c.bool_val(true);
  switch(p->type) {
    case typeCon: { if (p->con.dtype == 'i') return c.int_val(p->con.value);
                    else return c.bool_val(p->con.value);
    }
    case typeId: return sym[p->id.i][p->id.j];

    case typeOpr:

      switch(p->opr.oper) {
        case INT: return sym[p->opr.op[0]->id.i][p->opr.op[0]->id.j];
        case BOOLEAN: return sym[p->opr.op[0]->id.i][p->opr.op[0]->id.j];

        case FORALL: return forall(sym[p->opr.op[0]->id.i][p->opr.op[0]->id.j], make_condition(p->opr.op[1]));
        case EXISTS: return exists(sym[p->opr.op[0]->id.i][p->opr.op[0]->id.j], make_condition(p->opr.op[1]));

        case ';': make_condition(p->opr.op[0]); return make_condition(p->opr.op[1]);
        case '=': std::cout<<"assign\n"; return sym[p->opr.op[0]->id.i][p->opr.op[0]->id.j] = make_condition(p->opr.op[1]);
        case UMINUS: return -make_condition(p->opr.op[0]);
        case '+': return make_condition(p->opr.op[0]) + make_condition(p->opr.op[1]);
        case '-': return make_condition(p->opr.op[0]) - make_condition(p->opr.op[1]);
        case '*': return make_condition(p->opr.op[0]) * make_condition(p->opr.op[1]);
        case '/': return make_condition(p->opr.op[0]) / make_condition(p->opr.op[1]);
        case '%': return mod(make_condition(p->opr.op[0]),make_condition(p->opr.op[1]));
        case '<': return make_condition(p->opr.op[0]) < make_condition(p->opr.op[1]);
        case '>': return make_condition(p->opr.op[0]) > make_condition(p->opr.op[1]);
        case GE: return make_condition(p->opr.op[0]) >= make_condition(p->opr.op[1]);
        case LE: return make_condition(p->opr.op[0]) <= make_condition(p->opr.op[1]);
        case NE: return make_condition(p->opr.op[0]) != make_condition(p->opr.op[1]);
        case EQ: return make_condition(p->opr.op[0]) == make_condition(p->opr.op[1]);
        case AND: return make_condition(p->opr.op[0]) && make_condition(p->opr.op[1]);
        case OR: return make_condition(p->opr.op[0]) || make_condition(p->opr.op[1]);
        case NOT: return !make_condition(p->opr.op[0]);
      }
  }
}

std::vector<std::vector<int>> intSym(26);

int ex(nodeType *p) {
  if (!p) return 0;
  switch(p->type) {
    case typeCon: return p->con.value;
    case typeId: return intSym[p->id.i][p->id.j];
    case typeOpr:
      switch(p->opr.oper) {
        case ';': ex(p->opr.op[0]); return ex(p->opr.op[1]);
        case '=': return intSym[p->opr.op[0]->id.i][p->opr.op[0]->id.j] = ex(p->opr.op[1]);
        case UMINUS: return -ex(p->opr.op[0]);
        case '+': return ex(p->opr.op[0]) + ex(p->opr.op[1]);
        case '-': return ex(p->opr.op[0]) - ex(p->opr.op[1]);
        case '*': return ex(p->opr.op[0]) * ex(p->opr.op[1]);
        case '/': return ex(p->opr.op[0]) / ex(p->opr.op[1]);
      }
  }
  return 0;
} 

void updateSize(int index, int size) {
  while(sym[index].size() < size) {
    char s[] = {(char)(index+'a'), '[', (char)(sym[index].size() + '0'), ']'};
    sym[index].push_back(c.int_const(s));
  }
    // sym[index].resize(size);
  if(intSym[index].size() < size) {
    intSym[index].resize(size);
  }
}

expr weakest_pre(nodeType* p, expr wp){
  switch(p->type) {

    case typeOpr:

      switch(p->opr.oper) {

        case IF: 
          return implies(make_condition(p->opr.op[0]), weakest_pre(p->opr.op[1],wp)) &&
           implies(!make_condition(p->opr.op[0]), weakest_pre(p->opr.op[2],wp));

        case ';': return weakest_pre(p->opr.op[0],weakest_pre(p->opr.op[1],wp));

        case '=': {
          Z3_ast from[] = { sym[p->opr.op[0]->id.i][0] };
          Z3_ast to[]   = { make_condition(p->opr.op[1]) };
          expr new_f(c);
          new_f = to_expr(c, Z3_substitute(c, wp, 1, from, to));
          return new_f;
      }

        case WHILE:{
          expr inv = make_condition(p->opr.op[1]);
          expr cond = make_condition(p->opr.op[0]);

          expr conjecture = implies(inv && cond, weakest_pre(p->opr.op[2],inv)) && implies(inv && !cond,wp);
          solver s(c);
          s.add(!conjecture);
          switch (s.check()) {
              case unsat:   return inv;
              case sat:     { model m = s.get_model(); 
                              std::cout << "Loop invariant failed, Counterexample:\n"<<m<<"\n"; 
                              exit(0); }
              case unknown: exit(0);
            }
        }
  }
}
}

void execute(){
  for(int i=0;i<26;i++){
    char s[] = {i+97};
    if (dtype[i] == 'i' && sym[i].empty()) {
      sym[i] = std::vector<expr>({c.int_const(s)});
    }
    else if(sym[i].empty()) sym[i] = std::vector<expr>({c.bool_const(s)});
  }
  std::reverse(stmts.begin(),stmts.end());

  expr pre_condition = make_condition(stmts[stmts.size()-1]->opr.op[0]);
  expr post_condition = make_condition(stmts[0]->opr.op[0]);
  std::cout<<"Pre condition: "<<pre_condition<<std::endl;
  // std::cout<<post_condition<<std::endl;
  expr wp = post_condition;
  std::cout<<"0: "<<wp<<std::endl;
  for(int i=1; i<stmts.size()-1;i++){
    wp = weakest_pre(stmts[i],wp);
    std::cout<<i<<": "<<wp<<std::endl;
  }

  solver s(c);
  s.add(!implies(pre_condition,wp));
  std::cout << s.to_smt2() << "\n";

  switch (s.check()) {
    case unsat:   std::cout << "Hoare triple is valid\n"; break;
    case sat:     { model m = s.get_model(); 
                    std::cout << "Hoare triple is not valid, Counterexample:\n"<<m<<"\n"; 
                    break; }
    case unknown: std::cout << "unknown\n"; break;
  }
}

