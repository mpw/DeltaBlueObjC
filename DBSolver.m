//
//  DBSolver.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import "DBSolver.h"
#import <objc/runtime.h>
#import "DBVariable.h"

#define OUT_VAR(c)	(c->variables[c->methodOuts[c->whichMethod]])


@implementation DBSolver

+(instancetype)solver
{
    static DBSolver *solver=nil;
    if ( !solver ) {
        solver=[self new];
    }
    return solver;
}


-(void)initDeltaBlue
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
    allVariables=[NSMutableArray array];
    hot = List_Create(100000);
    todo1 = List_Create(100000);
    todo2 = List_Create(100000);
    currentMark = 0;
}

-(instancetype)init
{
    self=[super init];
    [self initDeltaBlue];
    return self;
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

-(void)addVariable:(DBVariable*)v
{
    [allVariables addObject:v];
}


-(void)destroyVariable:(DBVariable*)var
{
    Variable v=[var variable];
    Constraint c;
    
    c = (Constraint) List_RemoveFirst(v->constraints);
    while (c != NULL) {
        [self destroyConstraint:c];
        c = (Constraint) List_RemoveFirst(v->constraints);
    }
    [allVariables removeObject:var];
    Variable_Destroy(v);
}

-(void)addConstraint:(Constraint)c
{
    register int i;
    
    for (i = c->varCount - 1; i >= 0; i--) {
        List_Add((c->variables[i])->constraints, (Element) c);
    }
    c->whichMethod = NO_METHOD;
    [self incrementalAdd:c];
}

-(void)destroyConstraint:(Constraint)c
{
    register int i;
    
    if (SATISFIED(c)) {
        [self incrementalRemove:c];
    }
    
    for (i = c->varCount - 1; i >= 0; i--) {
        List_Remove((c->variables[i])->constraints, (Element) c);
    }
    Constraint_Destroy(c);
}

/******** Public: Plan Extraction *******/


-(void)addIfSatisfiedInput:(Constraint)c
{
    if (c->inputFlag && SATISFIED(c)) {
        List_Add(hot, c);
    }
}

-(void)withList:(List)aList do:(SEL)selector
{
    for (int i=aList->first,max=aList->last; i<max;i++) {
        
        objc_msgSend( self, selector, aList->slots + i);
    }
}

-(void)withArray:(NSArray*)aList do:(SEL)selector
{
    for ( id obj in aList) {
        [self performSelector:selector withObject:obj];
    }
}



-(void)collectSatisfiedInputs:(DBVariable*)var
{
    Variable v=[var variable];
    [self withList:v->constraints do:@selector(addIfSatisfiedInput:)];
}

-(List)extractPlan
{
    if (hot == NULL) hot = List_Create(128);
    List_RemoveAll(hot);
    
    
    [self withArray:allVariables do:@selector(collectSatisfiedInputs:)];
//    List_Do(allVariables, CollectSatisfiedInputs);
    return [self makePlan];
}

-(List)extractPlanFromConstraint:(Constraint)c
{
    if (hot == NULL) hot = List_Create(128);
    List_RemoveAll(hot);
    [self addIfSatisfiedInput:c];
    return [self makePlan];
}

-(List)extractPlanFromConstraints:(List)constraints
{
    if (hot == NULL) hot = List_Create(128);
    List_RemoveAll(hot);
    [self withList:constraints do:@selector(addIfSatisfiedInput:)];

    return [self makePlan];
}

/******* Private: Plan Extraction *******/

-(List)makePlan
{
    register List	plan;
    register Constraint	nextC;
    register Variable	out;
    
    [self newMark];
    plan = List_Create(50000);
    nextC = (Constraint) List_RemoveFirst(hot);
    while (nextC != NULL) {
        out = OUT_VAR(nextC);
        if ((out->mark != currentMark) && [self inputsKnown:nextC]) {
            List_Add(plan, nextC);
            out->mark = currentMark;
            nextC = [self nextDownstreamConstraintFrom:hot variable:out];
        } else {
            nextC = (Constraint) List_RemoveFirst(hot);
        }
    }
    return plan;
}

-(bool)inputsKnown:(Constraint)c
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

-(void)incrementalAdd:(Constraint)c
{
    register Constraint overridden;
    
    [self newMark];
    overridden = [self satisfy:c];
    while (overridden != NULL) {
        overridden = [self satisfy:overridden];
    }
}

-(Constraint)satisfy:(Constraint)c
{
    register int	outIndex, i;
    register Constraint	overridden;
    register Variable	out;
    
    c->whichMethod = [self chooseMethod:c];
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
        if (![self addPropagate:c]) {
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

-(int)chooseMethod:(Constraint)c
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

-(bool)addPropagate:(Constraint)c
{
    register Constraint	nextC;
    register Variable	out;
    
    List_RemoveAll(todo1);
    nextC = c;
    while (nextC != NULL) {
        out = OUT_VAR(nextC);
        if (out->mark == currentMark) {
            /* remove the cycle-causing constraint */
            [self incrementalRemove:c];
            return false;
        }
        [self recalculate:c];
        nextC=[self nextDownstreamConstraintFrom:todo1 variable:out];
    }
    return true;
}

/******* Private: Removing *******/


-(void)addConstraintAtStrength:(Constraint)c
{
    if (c->strength == strength) {
        [self incrementalAdd:c];
    }
}

-(void)collectUnsatisfied:(Constraint)c
{
    if (!SATISFIED(c)) List_Add(unsatisfied, c);
}

-(void)incrementalRemove:(Constraint)c
{
    Variable out;
    register int i;
    
    out = OUT_VAR(c);
    c->whichMethod = NO_METHOD;
    for (i = c->varCount - 1; i >= 0; i--) {
        List_Remove((c->variables[i])->constraints, (Element) c);
    }
    unsatisfied = List_Create(8);
    [self removePropagateFrom:out];
    for (strength = S_required; strength <= S_weakest; strength++) {
        [self withList:unsatisfied do:@selector(addConstraintAtStrength:)];
        
//        List_Do(unsatisfied, AddAtStrength);
    }
    List_Destroy(unsatisfied);
}

-(void)removePropagateFrom:(Variable)v
{
    register Constraint	nextC;
    
    List_RemoveAll(todo2);
    v->determinedBy = NULL;
    v->walkStrength = S_weakest;
    v->stay = true;
    while (true) {
        
        [self withList:v->constraints do:@selector(collectUnsatisfied:)];

        
//        List_Do(v->constraints, CollectUnsatisfied);
        nextC = [self nextDownstreamConstraintFrom:todo2 variable:v];
//        NextDownstreamConstraint(todo2, v);
        if (nextC == NULL) {
            break;
        } else {
            [self recalculate:nextC];
            v = OUT_VAR(nextC);
        }
    }
}

/******* Private: Recalculation *******/

-(void)recalculate:(Constraint)c
{
    register Variable out;
    
    out = OUT_VAR(c);
    out->walkStrength = [self outputWalkStrength:c];
    out->stay = [self constantOutput:c];
    if (out->stay) c->execute(c);
}

-(int)outputWalkStrength:(Constraint)c
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

-(bool)constantOutput:(Constraint)c
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

-(void)newMark
{
    currentMark++;
}


-(Constraint)nextDownstreamConstraintFrom:(List)todo variable:(Variable)variable
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

void AddConstraint( Constraint c)
{
    [[DBSolver solver] addConstraint:c];
}

void DestroyConstraint( Constraint c)
{
    [[DBSolver solver] destroyConstraint:c];
}

@end
