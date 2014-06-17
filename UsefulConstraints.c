/***************************************************************************
 UsefulConstraints.c

    Some useful constraints.

****************************************************************************/
 
#include <stdio.h>
#include "List.h"
#include "Constraints.h"
#include "DeltaBlue.h"
#include "UsefulConstraints.h"

/* macro to reference a constraint variable value */
#define var(i) ((c->variables[i])->value)

/******* Stay Constraint *******/

Constraint StayC(v, strength)
Variable v;
int strength;
{
    Constraint new = Constraint_Create(1, strength);
    new->variables[0] = v;
    new->methodCount = 1;
    new->methodOuts[0] = 0;
    AddConstraint(new);
    return new;
};

/******* Edit Constraint *******/

Constraint EditC(v, strength)
Variable v;
int strength;
{
    Constraint new = Constraint_Create(1, strength);
    new->inputFlag = true;
    new->variables[0] = v;
    new->methodCount = 1;
    new->methodOuts[0] = 0;
    AddConstraint(new);
    return new;
};

/****** Equals Constraint ******/

void EqualsC_Execute(Constraint);
static void EqualsC_Execute(c)
register Constraint c;
{
    /* a = b */
   switch (c->whichMethod) {
    case 0:
	var(0) = var(1);
	break;
    case 1:
	var(1) = var(0);
	break;
    }
}

Constraint EqualsC(a, b, strength)
Variable a, b;
int strength;
{
    Constraint new = Constraint_Create(2, strength);
    new->execute = EqualsC_Execute;
    new->variables[0] = a;
    new->variables[1] = b;
    new->methodCount = 2;
    new->methodOuts[0] = 0;
    new->methodOuts[1] = 1;
    AddConstraint(new);
    return new;
};

/******** Add Constraint *******/

void AddC_Execute(Constraint);
static void AddC_Execute(c)
register Constraint c;
{
    /* a + b = sum */
    switch (c->whichMethod) {
    case 0:
	var(2) = var(0) + var(1);
	break;
    case 1:
	var(1) = var(2) - var(0);
	break;
    case 2:
	var(0) = var(2) - var(1);
	break;
    }
}

Constraint AddC(a, b, sum, strength)
Variable a, b, sum;
int strength;
{
    Constraint new = Constraint_Create(3, strength);
    new->execute = AddC_Execute;
    new->variables[0] = a;
    new->variables[1] = b;
    new->variables[2] = sum;
    new->methodCount = 3;
    new->methodOuts[0] = 2;
    new->methodOuts[1] = 1;
    new->methodOuts[2] = 0;
    AddConstraint(new);
    return new;
};

/******** Multiply Constraint *******/

void MultiplyC_Execute(Constraint);
static void MultiplyC_Execute(c)
register Constraint c;
{
    /* a * b = prod */
    switch (c->whichMethod) {
    case 0:
	var(2) = var(0) * var(1);
	break;
    case 1:
	var(1) = var(2) / var(0);
	break;
    case 2:
	var(0) = var(2) / var(1);
	break;
    }
}

Constraint MultiplyC(a, b, prod, strength)
Variable a, b, prod;
int strength;
{
    Constraint new = Constraint_Create(3, strength);
    new->execute = MultiplyC_Execute;
    new->variables[0] = a;
    new->variables[1] = b;
    new->variables[2] = prod;
    new->methodCount = 3;
    new->methodOuts[0] = 2;
    new->methodOuts[1] = 1;
    new->methodOuts[2] = 0;
    AddConstraint(new);
    return new;
};

/******** ScaleOffset Constraint *******/

void ScaleOffsetC_Execute(Constraint);
static void ScaleOffsetC_Execute(c)
register Constraint c;
{
    /* (src * scale) + offset = dest */
    switch (c->whichMethod) {
    case 0:
	var(3) = (var(0) * var(1)) + var(2);
	break;
    case 1:
	var(0) = (var(3) - var(2)) / var(1);
	break;
    }
}

Constraint ScaleOffsetC(src, scale, offset, dest, strength)
Variable src, scale, offset, dest;
int strength;
{
    Constraint new = Constraint_Create(4, strength);
    new->execute = ScaleOffsetC_Execute;
    new->variables[0] = src;
    new->variables[1] = scale;
    new->variables[2] = offset;
    new->variables[3] = dest;
    new->methodCount = 2;
    new->methodOuts[0] = 3;
    new->methodOuts[1] = 0;
    AddConstraint(new);
    return new;
};
