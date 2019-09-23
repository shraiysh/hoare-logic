# Hoare Logic

### Sample Code
```
x = 0;
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
