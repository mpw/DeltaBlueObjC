/***************************************************************************
 Constraints.h

    Constraint, variable, and strength data definitions for DeltaBlue.

****************************************************************************/

#import <Foundation/Foundation.h>


typedef struct {
  long		value;
  NSMutableArray *		constraints;
  void *	determinedBy; /* Constraint */
  long		mark;
  char		walkStrength;
  bool      stay;
  char		name[10];
} *Variable, VariableStruct;

typedef struct {
  Proc		execute;
  bool      inputFlag;
  char		strength;
  char		whichMethod;
  char		methodCount;
  char		varCount;
  char		methodOuts[7];
  Variable	variables[1];
  NSMutableArray *objvariables;
} *Constraint, ConstraintStruct;

/* Variables */
  Variable	Variable_Create(char *, long);
  Variable	Variable_CreateConstant(char *, long);
  void		Variable_Destroy(Variable);
  void		Variable_Print(Variable);
  long      Variable_Value(Variable v);

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
