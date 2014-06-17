/***************************************************************************
 Constraints.h

    Constraint, variable, and strength data definitions for DeltaBlue.

****************************************************************************/

typedef struct {
  long		value;
  List		constraints;
  void *	determinedBy; /* Constraint */
  long		mark;
  char		walkStrength;
  Boolean	stay;
  char		name[10];
} *Variable, VariableStruct;

typedef struct {
  Proc		execute;
  Boolean	inputFlag;
  char		strength;
  char		whichMethod;
  char		methodCount;
  char		varCount;
  char		methodOuts[7];
  Variable	variables[1];
} *Constraint, ConstraintStruct;

/* Variables */
  Variable	Variable_Create(char *, long);
  Variable	Variable_CreateConstant(char *, long);
  void		Variable_Destroy(Variable);
  void		Variable_Print(Variable);

/* Constraints */
  Constraint	Constraint_Create(int, int);
  void		Constraint_Destroy(Constraint);
  void		Constraint_Print(Constraint);

/* Miscellaneous */
  void		ExecutePlan(List);
  char* 	StrengthString(int);

/* Strength Constants */
#define S_required		0
#define S_strongPreferred	1
#define S_preferred		2
#define S_strongDefault		3
#define S_default		4
#define S_weakDefault		5
#define S_weakest		6

/* Other Constants and Macros */
#define NO_METHOD	(-1)
#define SATISFIED(c)	((c)->whichMethod != NO_METHOD)
#define Weaker(a,b)	(a > b)
