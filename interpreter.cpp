#include <stdio.h>
#include "include.h"
#include "y.tab.h"
#include <vector>
#include<algorithm>
#include <z3++.h>
using namespace z3;
std::vector<nodeType*> stmts;
std::vector<expr> sym;

context c;

sort Int = c.int_sort();
sort MYARRAY = c.array_sort(Int, Int);

std::vector<expr> arr;

void add(nodeType* p){
  stmts.push_back(p);
}


expr make_condition(nodeType *p){
  int index;
  switch(p->type) {
    case typeCon: { if (p->con.dtype == 'i') return c.int_val(p->con.value);
                    else return c.bool_val(p->con.value);
    }
    case typeId: return sym[p->id.i];

    case typeOpr:

      switch(p->opr.oper) {
        case INT: return sym[p->opr.op[0]->id.i];
        case BOOLEAN: return sym[p->opr.op[0]->id.i];

        case ARR_ASSGN:
          index = p->opr.op[0]->id.i;
          arr[index] = store(arr[index], make_condition(p->opr.op[1]), make_condition(p->opr.op[2]));
          return arr[index];
        
        case ARR_ACCESS:
          return select(arr[p->opr.op[0]->id.i], make_condition(p->opr.op[1]));

        case FORALL: return forall(sym[p->opr.op[0]->id.i], make_condition(p->opr.op[1]));
        case EXISTS: return exists(sym[p->opr.op[0]->id.i], make_condition(p->opr.op[1]));

        case ';': make_condition(p->opr.op[0]); return make_condition(p->opr.op[1]);
        case '=': std::cout<<"assign\n"; return sym[p->opr.op[0]->id.i] = make_condition(p->opr.op[1]);
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

expr weakest_pre(nodeType* p, expr wp){
  switch(p->type) {

    case typeOpr:

      switch(p->opr.oper) {

        case IF: {
          std::cout << "HANDLING IF\n";
          auto true_conj = implies(make_condition(p->opr.op[0]), weakest_pre(p->opr.op[1],wp));
          auto false_conj = implies(!make_condition(p->opr.op[0]), weakest_pre(p->opr.op[2],wp));
          std::cout << "---------\nIF CONDITION:\n\tTRUE : " << true_conj;
          std::cout << "\n\tFALSE : " << false_conj << "\n---------\n";
          return true_conj && false_conj;
        }

        case ';': {
          // std::cout << "HANLDING SEMICOLON\n";
          auto a = weakest_pre(p->opr.op[1],wp);
          auto b = weakest_pre(p->opr.op[0],a);
          // std::cout << "--------\nSEMICOLON: " << b << "\n--------\n";
          return b;
        }

        case ARR_ASSGN: {
          std::cout << "HANDLING ASSIGNMENT\n";
          Z3_ast from1[] = { arr[p->opr.op[0]->id.i] };
          Z3_ast to1[]   = { store(arr[p->opr.op[0]->id.i], make_condition(p->opr.op[1]), make_condition(p->opr.op[2])) };
          expr new_f1(c);
          new_f1 = to_expr(c, Z3_substitute(c, wp, 1, from1, to1));
          std::cout << "---------\nARRAY ASSIGNMENT:" << new_f1 << "\n---------\n";
          return new_f1;
        }
          // return wp && arr[p->opr.op[0]->id.i] == store(arr[p->opr.op[0]->id.i], make_condition(p->opr.op[1]), make_condition(p->opr.op[2]));

        case '=': {
          std::cout << "HANDLING ASSIGNMENT\n";
          Z3_ast from[] = { sym[p->opr.op[0]->id.i] };
          Z3_ast to[]   = { make_condition(p->opr.op[1]) };
          expr new_f(c);
          new_f = to_expr(c, Z3_substitute(c, wp, 1, from, to));
          std::cout << "---------\nASSIGNMENT:" << new_f << "\n---------\n";
          return new_f;
      }

        case WHILE:{
          std::cout << "HANDLING WHILE\n";
          expr inv = make_condition(p->opr.op[1]);
          expr cond = make_condition(p->opr.op[0]);

          auto weak_pre_body = weakest_pre(p->opr.op[2],inv);
          expr conjecture = implies(inv && cond, weak_pre_body) && implies(inv && !cond,wp);
          std::cout << "WHILE ({Inv && B => weakest_pre(body)} && {Inv && !B => weakest_pre(after body)}): " << conjecture << "\n---------\n";
          // std::cout<<conjecture<<std::endl;
          solver s(c);
          s.add(!conjecture);
          switch (s.check()) {
              case unsat:   return inv;
              case sat:     { model m = s.get_model(); 
                              std::cout << "Loop invariant failed, Counterexample:\n";
                              for (unsigned i = 0; i < m.size(); i++) {
                                  func_decl v = m[i];
                                  // this problem contains only constants
                                  assert(v.arity() == 0); 
                                  std::cout << v.name() << " = " << m.get_const_interp(v) << "\n";
                              } 
                              exit(0); }
              case unknown: exit(0);
            }
        }
    }
  }
  return wp;
}

void execute(){
  for(int i=0;i<26;i++){
    char s[] = {i+97};
    if (dtype[i] == 'i') sym.push_back(c.int_const(s));
    else sym.push_back(c.bool_const(s));
  }
  for(int i=0;i<26;i++) {
    char s[] = {i+'A'};
    arr.push_back(c.constant(s, MYARRAY));
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
                    std::cout << "Hoare triple is not valid, Counterexample:\n";
                    for (unsigned i = 0; i < m.size(); i++) {
                        func_decl v = m[i];
                        // this problem contains only constants
                        assert(v.arity() == 0); 
                        std::cout << v.name() << " = " << m.get_const_interp(v) << "\n";
                    } 
                    break; }
    case unknown: std::cout << "unknown\n"; break;
  }
}

