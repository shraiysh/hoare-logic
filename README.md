# Hoare Logic

### Sample Code
 * There can be only 26 variables. Redeclaration of a variable over-writes the previous value and datatype
 * `print x` prints both value and type (`i` for int and `b` for bool)
 * Variables must be initialized
 * If a variable is not declared already, type is inferred from rhs
```
int x = 0;
bool y = (x < 3);
while (x < 3) {
 print x;
 x = x + 1;
}
```

### To Run
```bash
lex lexer.h
yacc -d parser.h
```
#### Run the code
```bash
gcc lex.yy.c y.tab.c -w interpreter.c
```

#### Generate code for hypothetical stack based machine
```bash
gcc lex.yy.c tab.c -w compiler.c
```

### Reference
* http://ftp.mozgan.me/Compiler_Manuals/LexAndYaccTutorial.pdf
