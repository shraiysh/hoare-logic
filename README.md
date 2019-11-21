# Hoare Logic

### Sample Code
 * There can be only 26 variables(```int``` and ```bool``` - ```a``` to ```z```). Any type of assignment is possible after declaration only
 * There are 26 integer arrays - ```A``` to ```Z```
 * Two dataypes ```int``` and ```bool```
 * ```pre``` stands for precondition. ```post``` for post condition and ```inv``` for loop invariant
 * ```@``` stands for universal quantifier and ```#``` stands for existensial quantifier
 * Datatypes of free variables need to be mentioned. Arrays are already of int type

#### Valid Hoare Triples

```
pre true;
A[0] = 1;
post A[0]==1;
```
---
```
pre {
	int n;
	n>0;
}
n=5;
A[3] = n;
post A[3] == 5;
```
---
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
---
```
pre {
	int x;
	(x>0); 
}

if (x%2 == 0){
	x = x+1;
}
else {
	x = x+2;
}

post x%2 == 1;
```

#### Invalid Hoare triples

```
pre true;
A[0] = 1;
post A[0]==2;
```
---
```
pre {
	int i;
	i<0;
}
post i>0;
```

Check ```tests``` for more examples.

### To Run
Install [z3 solver](https://github.com/Z3Prover/z3)
```bash
make
./a.out < tests/copy.txt
```
### Output
* Proves the correctness of hoare-triple. Provides counter-example if fails.

### Reference
* https://www.cs.cmu.edu/~aldrich/courses/654-sp07/slides/7-hoare.pdf
* http://ftp.mozgan.me/Compiler_Manuals/LexAndYaccTutorial.pdf
* https://github.com/Z3Prover/z3
