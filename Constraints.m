/***************************************************************************
 Constraints.c

    Constraint, variable, and other operations for DeltaBlue.

****************************************************************************/

#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import "List.h"
#import "Constraints.h"
#import "DeltaBlue.h"

#import "DBVariable.h"
#import "DBConstraint.h"
#import "DBSolver.h"

/******* Private *******/

static void Error(char*);
static void Error(errorString)
char* errorString;
{
    printf("Constraints.c error: %s.\n", errorString);
    exit(-1);
}

static void Noop(Constraint);
static void Noop(c)
Constraint c;
{
    /* default execute procedure; does nothing */
};

/******* Variables *******/

Variable Variable_Create()
{
    register Variable new;

    new = (Variable) malloc(sizeof(VariableStruct));
    if (new == NULL) Error("out of memory");
    new->constraints = [NSMutableArray new];


    new->determinedBy = NULL;
    new->mark = 0;
    new->walkStrength = S_weakest;
    new->stay = true;

    return new;
}

Variable Variable_CreateConstant()
{
    register Variable new;

    new = (Variable) malloc(sizeof(VariableStruct));
    if (new == NULL) Error("out of memory");
    new->constraints = [NSMutableArray new];
    new->determinedBy = NULL;
    new->mark = 0;
    new->walkStrength = S_required;
    new->stay = true;
    return new;
}

void Variable_Destroy(v)
Variable v;
{
    if (v->constraints == NULL) {
	Error("bad VariableStruct; already freed?");
    }
    [v->constraints release];

    v->constraints = NULL;
    free(v);
}

/******* Constraints *******/

Constraint Constraint_Create(int variableCount, int strength)
{
    register Constraint new;
    int i;

    new = (Constraint) malloc(sizeof(ConstraintStruct) + ((variableCount - 1) * sizeof(Variable)));
    if (new == NULL) Error("out of memory");
    new->execute = Noop;
    new->inputFlag = false;
    new->strength = strength;
    new->whichMethod = NO_METHOD;
    new->methodCount = 0;
    for (i = 0; i < 7; i++) {
    	new->methodOuts[i] = 0;
    }
    new->varCount = variableCount;
    for (i = 0; i < new->varCount; i++) {
    	new->variables[i] = NULL;
    }
    return new;
}

void Constraint_Destroy(c)
Constraint c;
{
    if (c->execute == NULL) {
	Error("bad ConstraintStruct; already freed?");
    }
    c->execute = NULL;
    free(c);
}

void Constraint_Print(c)
Constraint c;
{
    int i, outIndex;

    if (!SATISFIED(c)) {
	printf("Unsatisfied(");
	for (i = 0; i < c->varCount; i++) {
        printf("%s",[[c->variables[i] description] UTF8String]);
        
	    printf(" ");
	}
	printf(")");
    } else {
	outIndex = c->methodOuts[c->whichMethod];
	printf("Satisfied(");
	for (i = 0; i < c->varCount; i++) {
	    if (i != outIndex) {
            printf("%s",[[c->variables[i] description] UTF8String]);
		printf(" ");
	    }
	}
	printf("-> ");
        printf("%s",[[c->variables[outIndex] description] UTF8String]);
	printf(")");
    }
    printf("\n");
}

/******* Miscellaneous Functions *******/

char* StrengthString(strength)
int strength;
{
    static char temp[20];

    switch (strength) {
    case S_required:		return "required";
    case S_strongPreferred:	return "strongPreferred";
    case S_preferred:		return "preferred";
    case S_strongDefault:	return "strongDefault";
    case S_default:		return "default";
    case S_weakDefault:		return "weakDefault";
    case S_weakest:		return "weakest";
    default:
	sprintf(temp, "strength[%d]", strength);
	return temp;
    }
}

void ExecutePlan(NSArray *plan)
{
    for (DBConstraint *c in plan) {
        [c execute];
    }

}
