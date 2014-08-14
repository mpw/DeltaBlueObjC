/******************************************************************************
 DeltaBlue.c

    DeltaBlue incremental constraint solver.

*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#import "List.h"
#import "Constraints.h"
#import "DeltaBlue.h"
#import "List.h"

#import <Foundation/Foundation.h>



/******* Private Macros and Prototypes *******/

#define OUT_VAR(c)	(c->variables[c->methodOuts[c->whichMethod]])

static void		FreeVariable(Variable);
static void		AddIfSatisfiedInput(Constraint);
static void		CollectSatisfiedInputs(Variable);
static List		MakePlan(void);
static void		IncrementalAdd(Constraint);
static void		AddAtStrength(Constraint);
static void		IncrementalRemove(Constraint);
static bool		AddPropagate(Constraint);
static void		CollectUnsatisfied(Constraint);
static void		RemovePropagateFrom(Variable);
static Constraint	Satisfy(Constraint);
static int		ChooseMethod(Constraint);
static void		Recalculate(Constraint);
static int		OutputWalkStrength(Constraint);
static bool		ConstantOutput(Constraint);
static bool		InputsKnown(Constraint);
static void		NewMark(void);
static void		Error(char *);
static Constraint	NextDownstreamConstraint(List, Variable);

/******* DeltaBlue Globals *******/

List allVariables = NULL;
static long currentMark = 0;
static List hot = NULL;	/* used to collect "hot" constraints */
static List todo1 = NULL; /* used by AddPropagate */
static List todo2 = NULL; /* used by RemovePropagate */

/******** Public: Initialization *******/

void InitDeltaBlue(void)
{
//    Variable v;

/*
    if (allVariables == NULL) allVariables = List_Create(128);
    v = (Variable) List_RemoveFirst(allVariables);
    while (v != NULL) {
	FreeVariable(v);
	v = (Variable) List_RemoveFirst(allVariables);
    }
    List_RemoveAll(allVariables);
    currentMark = 0;
*/
    allVariables = List_Create(100000);
    hot = List_Create(100000);
    todo1 = List_Create(100000);
    todo2 = List_Create(100000);
    currentMark = 0;
}

/* this is used when we know we are going to throw away all variables */
static void FreeVariable(v)
Variable v;
{
    Constraint c;
    int i;

    c = (Constraint) List_RemoveFirst(v->constraints);
    while (c != NULL) {
	for (i = c->varCount - 1; i >= 0; i--) {
	   List_Remove((c->variables[i])->constraints, (Element) c);
	}
	Constraint_Destroy(c);
	c = (Constraint) List_RemoveFirst(v->constraints);
    }
    Variable_Destroy(v);
}

/******** Public: Variables and Constraints *******/

void AddVariable(v)
Variable v;
{
    List_Add(allVariables, v);
}

void DestroyVariable(v)
Variable v;
{
    Constraint c;

    c = (Constraint) List_RemoveFirst(v->constraints);
    while (c != NULL) {
	DestroyConstraint(c);
	c = (Constraint) List_RemoveFirst(v->constraints);
    }
    List_Remove(allVariables, v);
    Variable_Destroy(v);
}

void AddConstraint(c)
register Constraint c;
{
    register int i;

    for (i = c->varCount - 1; i >= 0; i--) {
	List_Add((c->variables[i])->constraints, (Element) c);
    }
    c->whichMethod = NO_METHOD;
    IncrementalAdd(c);
}

void DestroyConstraint(c)
register Constraint c;
{
    register int i;

    if (SATISFIED(c)) IncrementalRemove(c);
    for (i = c->varCount - 1; i >= 0; i--) {
	List_Remove((c->variables[i])->constraints, (Element) c);
    }
    Constraint_Destroy(c);
}

/******** Public: Plan Extraction *******/

static void AddIfSatisfiedInput(c)
Constraint c;
{
    if (c->inputFlag && SATISFIED(c)) {
	List_Add(hot, c);
    }
}


static void CollectSatisfiedInputs(v)
Variable v;
{
    List_Do(v->constraints, AddIfSatisfiedInput);
}

List ExtractPlan(void)
{
    if (hot == NULL) hot = List_Create(128);
    List_RemoveAll(hot);
    List_Do(allVariables, CollectSatisfiedInputs);
    return MakePlan();
}

List ExtractPlanFromConstraint(c)
Constraint c;
{
    if (hot == NULL) hot = List_Create(128);
    List_RemoveAll(hot);
    AddIfSatisfiedInput(c);
    return MakePlan();
}

List ExtractPlanFromConstraints(constraints)
List constraints;
{
    if (hot == NULL) hot = List_Create(128);
    List_RemoveAll(hot);
    List_Do(constraints, AddIfSatisfiedInput);
    return MakePlan();
}

/******* Private: Plan Extraction *******/

static List MakePlan()
{
    register List	plan;
    register Constraint	nextC;
    register Variable	out;

    NewMark();
    plan = List_Create(50000);
    nextC = (Constraint) List_RemoveFirst(hot);
    while (nextC != NULL) {
	out = OUT_VAR(nextC);
	if ((out->mark != currentMark) && InputsKnown(nextC)) {
	    List_Add(plan, nextC);
	    out->mark = currentMark;
	    nextC = NextDownstreamConstraint(hot, out);
	} else {
	    nextC = (Constraint) List_RemoveFirst(hot);
	}
    }
    return plan;
}

static bool InputsKnown(c)
register Constraint c;
{
    register int	outIndex, i;
    register Variable	in;

    outIndex = c->methodOuts[c->whichMethod];
    for (i = c->varCount - 1; i >= 0; i--) {
	if (i != outIndex) {
	    in = c->variables[i];
	    if ((in->mark != currentMark) &&
	    	(!in->stay) &&
		(in->determinedBy != NULL)) {
		    return false;
	    }
	}
    }
    return true;
}

/******* Private: Adding *******/

static void IncrementalAdd(c)
Constraint c;
{
    register Constraint overridden;

    NewMark();
    overridden = Satisfy(c);
    while (overridden != NULL) {
	overridden = Satisfy(overridden);
    }
}

static Constraint Satisfy(c)
register Constraint c;
{
    register int	outIndex, i;
    register Constraint	overridden;
    register Variable	out;

    c->whichMethod = ChooseMethod(c);
    if (SATISFIED(c)) {
	/* mark inputs to allow cycle detection in AddPropagate */
	outIndex = c->methodOuts[c->whichMethod];
	for (i = c->varCount - 1; i >= 0; i--) {
	    if (i != outIndex) {
		c->variables[i]->mark = currentMark;
	    }
	}
	out = c->variables[outIndex];
	overridden = (Constraint) out->determinedBy;
	if (overridden != NULL) overridden->whichMethod = NO_METHOD;
	out->determinedBy = c;
	if (!AddPropagate(c)) {
	    Error("Cycle encountered");
	    return NULL;
	}
	out->mark = currentMark;
	return overridden;
    } else {
	if (c->strength == S_required) {
	    Error("Could not satisfy a required constraint");
	}
	return NULL;
    }
}

static int ChooseMethod(c)
register Constraint c;
{
    register int	best, bestOutStrength, m;
    register Variable	mOut;

    best = NO_METHOD;
    bestOutStrength = c->strength;
    for (m = c->methodCount - 1; m >= 0; m--) {
	mOut = c->variables[c->methodOuts[m]];
	if ((mOut->mark != currentMark) &&
	     (Weaker(mOut->walkStrength, bestOutStrength))) {
		best = m;
		bestOutStrength = mOut->walkStrength;
	}
    }
    return best;
}

static bool AddPropagate(c)
register Constraint c;
{
    register Constraint	nextC;
    register Variable	out;
    
    List_RemoveAll(todo1);
    nextC = c;
    while (nextC != NULL) {
        out = OUT_VAR(nextC);
        if (out->mark == currentMark) {
            /* remove the cycle-causing constraint */
            IncrementalRemove(c);
            return false;
        }
        Recalculate(nextC);
        nextC = NextDownstreamConstraint(todo1, out);
    }
    return true;
}

/******* Private: Removing *******/

static List unsatisfied;	/* used to collect unsatisfied downstream constraints */
static int strength;		/* used to add unsatisfied constraints in strength order */

static void AddAtStrength(c)
register Constraint c;
{
    if (c->strength == strength) IncrementalAdd(c);
}

static void CollectUnsatisfied(c)
Constraint c;
{
    if (!SATISFIED(c)) List_Add(unsatisfied, c);
}

void IncrementalRemove(c)
Constraint c;
{
    Variable out;
    register int i;

    out = OUT_VAR(c);
    c->whichMethod = NO_METHOD;
    for (i = c->varCount - 1; i >= 0; i--) {
	List_Remove((c->variables[i])->constraints, (Element) c);
    }
    unsatisfied = List_Create(8);
    RemovePropagateFrom(out);
    for (strength = S_required; strength <= S_weakest; strength++) {
	List_Do(unsatisfied, AddAtStrength);
    }
    List_Destroy(unsatisfied);
}

static void RemovePropagateFrom(v)
register Variable v;
{
    register Constraint	nextC;

    List_RemoveAll(todo2);
    v->determinedBy = NULL;
    v->walkStrength = S_weakest;
    v->stay = true;
    while (true) {
	List_Do(v->constraints, CollectUnsatisfied);
	nextC = NextDownstreamConstraint(todo2, v);
	if (nextC == NULL) {
	    break;
	} else {
	    Recalculate(nextC);
	    v = OUT_VAR(nextC);
	}
    }
}

/******* Private: Recalculation *******/

static void Recalculate(c)
register Constraint c;
{
    register Variable out;

    out = OUT_VAR(c);
    out->walkStrength = OutputWalkStrength(c);
    out->stay = ConstantOutput(c);
    if (out->stay) c->execute(c);
}

static int OutputWalkStrength(c)
register Constraint c;
{
    register int outIndex, minStrength, m, mOutIndex;

    minStrength = c->strength;
    outIndex = c->methodOuts[c->whichMethod];
    for (m = c->methodCount - 1; m >= 0; m--) {
    	mOutIndex = c->methodOuts[m];
	if ((mOutIndex != outIndex) &&
	    (Weaker(c->variables[mOutIndex]->walkStrength, minStrength))) {
		minStrength = c->variables[mOutIndex]->walkStrength;
	}
    }
    return minStrength;
}

static bool ConstantOutput(c)
register Constraint c;
{
    register int outIndex, i;

    if (c->inputFlag) return false;
    outIndex = c->methodOuts[c->whichMethod];
    for (i = c->varCount - 1; i >= 0; i--) {
	if (i != outIndex) {
	    if (!c->variables[i]->stay) return false;
	}
    }
    return true;
}

/******* Private: Miscellaneous *******/

static void Error(s)
char *s;
{
    printf("DeltaBlue.c error: %s.\n", s);
    exit(-1);
}

static void NewMark(void)
{
    currentMark++; 
}

static Constraint NextDownstreamConstraint(todo, variable)
List todo;
Variable variable;
{
    List allC = variable->constraints;
    register Constraint *nextPtr = (Constraint *) &(allC->slots[allC->first]);
    register Constraint *lastPtr = (Constraint *) &(allC->slots[allC->last]);
    register Constraint determiningC = variable->determinedBy;
    Constraint first = NULL;
    
    for ( ; nextPtr <= lastPtr; nextPtr++) {
        if ((*nextPtr != determiningC) && SATISFIED(*nextPtr)) {
            if (first == NULL) {
                first = *nextPtr;
            } else {
                List_Add(todo, *nextPtr);
            }
        }
    }
    if (first == NULL) {
        first = (Constraint) List_RemoveFirst(todo);
    }
    return first;
}
