/***************************************************************************
 Constraints.c

    Constraint, variable, and other operations for DeltaBlue.

****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "List.h"
#include "Constraints.h"
#include "DeltaBlue.h"

#import "DBSolver.h"

/******* Private *******/

static void Error(char*);
static void Error(errorString)
char* errorString;
{
    printf("Constraints.c error: %s.\n", errorString);
    exit(-1);
}

static void Execute(Constraint);
static void Execute(c)
Constraint c;
{
    c->execute(c);
}

static void Noop(Constraint);
static void Noop(c)
Constraint c;
{
    /* default execute procedure; does nothing */
};

/******* Variables *******/

Variable Variable_Create(name, initialValue)
char *name;
long initialValue;
{
    register Variable new;

    new = (Variable) malloc(sizeof(VariableStruct));
    if (new == NULL) Error("out of memory");
    new->value = initialValue;
    new->constraints = List_Create(2);
    new->determinedBy = NULL;
    new->mark = 0;
    new->walkStrength = S_weakest;
    new->stay = true;
    strncpy(new->name, name, 10);
    new->name[9] = 0;
        

    return new;
}

Variable Variable_CreateConstant(name, value)
char *name;
long value;
{
    register Variable new;

    new = (Variable) malloc(sizeof(VariableStruct));
    if (new == NULL) Error("out of memory");
    new->value = value;
    new->constraints = List_Create(0);
    new->determinedBy = NULL;
    new->mark = 0;
    new->walkStrength = S_required;
    new->stay = true;
    strncpy(new->name, name, 10);
    new->name[9] = 0;
    return new;
}

void Variable_Destroy(v)
Variable v;
{
    if (v->constraints == NULL) {
	Error("bad VariableStruct; already freed?");
    }
    List_Destroy(v->constraints);
    v->constraints = NULL;
    free(v);
}

void Variable_Print(v)
Variable v;
{
    printf(
           "%s(%s,%ld)",
           v->name, StrengthString(v->walkStrength), v->value);
}

long Variable_Value(v)
Variable v;
{
    return v->value;
}

/******* Constraints *******/

Constraint Constraint_Create(variableCount, strength)
int variableCount, strength;
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
	    Variable_Print(c->variables[i]);
	    printf(" ");
	}
	printf(")");
    } else {
	outIndex = c->methodOuts[c->whichMethod];
	printf("Satisfied(");
	for (i = 0; i < c->varCount; i++) {
	    if (i != outIndex) {
		Variable_Print(c->variables[i]);
		printf(" ");
	    }
	}
	printf("-> ");
	Variable_Print(c->variables[outIndex]);
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

void ExecutePlan(list)
List list;
{
    List_Do(list, Execute);
}
