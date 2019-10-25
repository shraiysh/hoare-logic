# Hoare Logic

### Sample Code
 * There can be only 26 variables. Anyype of assignment is possible after declaration only.
 * Two dataypes ```int``` and ```bool```. 
 * ```pre``` stands for precondition. ```post``` for post condition and ```inv``` for loop invariant.
 * ```@``` stands for universal quantifier and ```#``` stands for existensial quantifier.
 * Datatypes of free variables need to be mentioned.

```
pre {
	int x;
	int y;
	(x>0) && (y>0)&& (x>=y);
}

int r;
r = x;

inv (x>0) && (y>0)&& (x>=y) && (r>=0) && (r<=x);
while(r>=y){
 	r = r - y;
}

post (x>0) && (y>0)&& (x>=y) && (r>=0) && (r<y) && (r>=0) && (r<=x);
```

### To Run
```bash
make clean
make
./a.out < tests/test2.txt
```
### Output
* Proves the correctness of hoare-triple. Provides counter-example if fails.

### Reference
* http://ftp.mozgan.me/Compiler_Manuals/LexAndYaccTutorial.pdf
