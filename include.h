typedef enum { typeCon, typeId, typeOpr } nodeEnum;

/* constants */
typedef struct {
  int value; /* value of constant */
  char dtype;
} conNodeType;

/* identifiers */
typedef struct {
  int i; /* subscript to sym array */
  int j;
  char dtype;
} idNodeType;

/* operators */
typedef struct {
  int oper; /* operator */
  int nops; /* number of operands */
  struct nodeTypeTag **op; /* operands */
} oprNodeType;

typedef struct nodeTypeTag {
  nodeEnum type; /* type of node */
  union {
    conNodeType con; /* constants */
    idNodeType id; /* identifiers */
    oprNodeType opr; /* operators */
  };
} nodeType;

extern char dtype[26];
