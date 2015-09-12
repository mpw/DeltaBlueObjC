/***************************************************************************
 Constraints.h

    Constraint, variable, and strength data definitions for DeltaBlue.

****************************************************************************/

#import <Foundation/Foundation.h>

@class DBVariable,DBConstraint;

typedef struct {
//  long		value;
  NSMutableArray *		constraints;
  long		mark;
  char		walkStrength;
  bool      stay;
} *Variable, VariableStruct;

typedef struct {
  Proc		execute;
  NSMutableArray *methodBlocks;
  bool      inputFlag;
  char		strength;
  char		whichMethod;
  char		methodCount;
  char		varCount;
  char		methodOuts[7];
  DBVariable	*variables[0];
} *Constraint, ConstraintStruct;

/* Variables */
  Variable	Variable_Create();
  Variable	Variable_CreateConstant();
  void		Variable_Destroy(Variable);

/* Constraints */
  Constraint	Constraint_Create(int, int);
  void		Constraint_Destroy(Constraint);
  void		Constraint_Print(Constraint);

/* Miscellaneous */
  void ExecutePlan(NSArray *plan);
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
