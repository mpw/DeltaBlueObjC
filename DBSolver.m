//
//  DBSolver.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import "DBSolver.h"
#import <objc/message.h>
#import "DBVariable.h"
#import "DBConstraint.h"

#import <ObjectiveSmalltalk/MPWBinding.h>


#define OUT_VAR(c)	(c->variables[c->methodOuts[c->whichMethod]])


@implementation NSMutableArray(removeFirst)

-(id)removeFirst
{
    id result=[self firstObject];
    if ( result) {
        [self removeObjectAtIndex:0];
    }
    return result;
}

@end

@implementation DBSolver

objectAccessor(NSMutableSet, bindings, setBindings)

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
    allVariables=[NSMutableArray new];
    hot = [NSMutableArray new];
    todo1 = [NSMutableArray new];
    todo2 = [NSMutableArray new];
    currentMark = 0;
}

-(instancetype)init
{
    self=[super init];
    [self initDeltaBlue];
    [self setBindings:[NSMutableSet set]];
    return self;
}

/* this is used when we know we are going to throw away all variables */
#if 0

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
#endif

/******** Public: Variables and Constraints *******/

-(void)addVariable:(DBVariable*)v
{
    [allVariables addObject:v];
    [v setSolver:self];
}


-(void)destroyVariable:(DBVariable*)var
{

    [self withArray:[var constraints] do:@selector(destroyConstraint:)];
    [allVariables removeObject:var];
}

-(void)addConstraint:(DBConstraint*)c
{
    int i;

    Constraint newConstraint = [c constraint];
    for (i = newConstraint->varCount - 1; i >= 0; i--) {
        [newConstraint->variables[i] addConstraint:c];
        
    }
    newConstraint->whichMethod = NO_METHOD;
//    NSLog(@"will do incrementalAdd:");
    [self incrementalAdd:c];
//    NSLog(@"did incrementalAdd");
}



-(void)addCConstraint:(Constraint)newConstraint
{
    DBConstraint *c=[DBConstraint constraintWithCConstraint:newConstraint];
    [self addConstraint:c];
}


-(void)destroyConstraint:(DBConstraint*)c
{
    if ( [c isSatisfied]) {
        [self incrementalRemoveObj:c];
    }
    [c destroy];
}

/******** Public: Plan Extraction *******/


-(void)addIfSatisfiedInputObj:(DBConstraint*)c
{
    if ( [c isSatisfiedInput]) {
        [hot addObject:c];
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
    [self withArray:[var constraints] do:@selector(addIfSatisfiedInputObj:)];
}

-(NSArray*)extractPlan
{
    [hot removeAllObjects];
    [self withArray:allVariables do:@selector(collectSatisfiedInputs:)];
    return [self makePlan];
}

-(NSArray*)extractPlanFromConstraint:(DBConstraint*)c
{
    [hot removeAllObjects];
    [self addIfSatisfiedInputObj:c];
    return [self makePlan];
}

-(NSArray*)extractPlanFromConstraints:(NSArray*)constraints
{
    [hot removeAllObjects];
    [self withArray:constraints do:@selector(addIfSatisfiedInputObj:)];

    return [self makePlan];
}

/******* Private: Plan Extraction *******/

-(NSArray*)makePlan
{
    NSMutableArray*	plan=[NSMutableArray array];
    DBConstraint	*nextC;
    
    [self newMark];
    
    
    nextC = [hot removeFirst];
    while (nextC != NULL) {
        DBVariable *out=[nextC outputVariable];
        
//        out = [OUT_VAR([nextC constraint]) variable];
        if (([out mark] != currentMark) && [self inputsKnown:[nextC constraint]]) {
            [plan addObject:nextC];
            [out setMark:currentMark];
            nextC = [self nextDownstreamConstraintFrom:hot variable:out];
        } else {
            nextC = [hot removeFirst];
        }
    }
    return plan;
}

-(bool)inputsKnown:(Constraint)c
{
    int	outIndex, i;
    
    outIndex = c->methodOuts[c->whichMethod];
    for (i = c->varCount - 1; i >= 0; i--) {
        if (i != outIndex) {
            if ( ![c->variables[i] isKnownWithMark:currentMark]) {
                return false;
            }
        }
    }
    return true;
}

/******* Private: Adding *******/

-(void)incrementalAdd:(DBConstraint *)c
{
//    NSLog(@"incrementalAdd: %p",c);
    DBConstraint *overridden=nil;
    
    [self newMark];
    overridden = [self satisfy:c];
    while (overridden != NULL) {
        overridden = [self satisfy:overridden];
    }
}

-(DBConstraint*)satisfy:(DBConstraint *)constraint
{
//    NSLog(@"satisfy: %p",c);
    int	outIndex, i;
    DBConstraint	*overridden=nil;
    DBVariable	*outVar;
    Constraint c = [constraint constraint];
    
    c->whichMethod = [self chooseMethod:c];
    if ( [constraint isSatisfied]) {
        /* mark inputs to allow cycle detection in AddPropagate */
        outIndex = c->methodOuts[c->whichMethod];
        for (i = c->varCount - 1; i >= 0; i--) {
//            NSLog(@"variable[%d]",i);
            if (i != outIndex) {
                [c->variables[i] variable]->mark = currentMark;
            }
        }
        
        outVar = c->variables[outIndex];
        overridden = [outVar determinedBy];
        if (overridden != nil) {
            [overridden clearMethod];
        }
        [outVar setDeterminedBy:constraint];

        if (![self addPropagate:[DBConstraint constraintWithCConstraint: c]]) {
            Error("Cycle encountered");
            return NULL;
        }
        [outVar setMark:currentMark];
        return overridden;
    } else {
        NSAssert5(c->strength != S_required, @"required constraint %@ not satisfied vars: %@  hot: %@  todo1: %@ todo2:%@",
                  [DBConstraint constraintWithCConstraint:c],allVariables,hot,todo1,todo2);
//        if (c->strength == S_required) {
//            Error("Could not satisfy a required constraint");
//        }
        return nil;
    }
}

-(int)chooseMethod:(Constraint)c
{
    register int	best, bestOutStrength, m;
    register Variable	mOut;
    
    best = NO_METHOD;
    bestOutStrength = c->strength;
    for (m = c->methodCount - 1; m >= 0; m--) {
        mOut = [c->variables[c->methodOuts[m]] variable];
        if ((mOut->mark != currentMark) &&
            (Weaker(mOut->walkStrength, bestOutStrength))) {
            best = m;
            bestOutStrength = mOut->walkStrength;
        }
    }
    return best;
}

-(bool)addPropagate:(DBConstraint*)c
{
//    NSLog(@"addPropagate: %p",c);
    DBConstraint	*nextC;
    
    [todo1 removeAllObjects];
    nextC = c;
    while (nextC != NULL) {
//        NSLog(@"nextC: %p",nextC);
        DBVariable	*out=[nextC outputVariable];
//        out = [OUT_VAR(nextC) variable];
        if ([out mark] == currentMark) {
            /* remove the cycle-causing constraint */
//            NSLog(@"remove: %p",c);
            [self incrementalRemoveObj:c];
            return false;
        }
        [self recalculate:nextC];
        nextC=[self nextDownstreamConstraintFrom:todo1 variable:out];
    }
    return true;
}

/******* Private: Removing *******/


-(void)addConstraintAtStrength:(DBConstraint *)c
{
    if ([c strength] == strength) {
        [self incrementalAdd:c];
    }
}

-(void)collectUnsatisfied:(DBConstraint*)constr
{
    if (! [constr isSatisfied] )  {
        List_Add(unsatisfied, [constr constraint]);
    }
}


-(void)incrementalRemoveObj:(DBConstraint*)objConstraint
{
    //    NSLog(@"remove %p",c);
    @autoreleasepool {
        DBVariable *outputVar;
        register int i;
        Constraint c=[objConstraint constraint];
        
        outputVar = OUT_VAR(c);
        c->whichMethod = NO_METHOD;
        
        
        
        
        for (i = c->varCount - 1; i >= 0; i--) {
            [[c->variables[i] variable]->constraints removeObject:objConstraint];
            
            
        }
        unsatisfied = [NSMutableArray array];
        [self removePropagateFrom:outputVar];
        for (strength = S_required; strength <= S_weakest; strength++) {
            [self withArray:unsatisfied do:@selector(addConstraintAtStrength:)];
            
        }
    }
//    Variable out;
}


-(void)removePropagateFrom:(DBVariable*)v
{
    [todo2 removeAllObjects];
    [v setDeterminedBy:nil];
    
    [v variable]->walkStrength = S_weakest;
    [v variable]->stay = true;
    while (true) {
        DBConstraint	*nextC;
        
        [self withArray:[v constraints] do:@selector(collectUnsatisfied:)];

        
//        List_Do(v->constraints, CollectUnsatisfied);
        nextC = [self nextDownstreamConstraintFrom:todo2 variable:v];
//        NextDownstreamConstraint(todo2, v);
        if (nextC == NULL) {
            break;
        } else {
            [self recalculate:nextC];
            v = [nextC outputVariable];
        }
    }
}

/******* Private: Recalculation *******/

-(void)recalculate:(DBConstraint*)constraint
{
//    NSLog(@"recalculate: %p",c);
    register Variable out;
    Constraint c=[constraint constraint];
    
    out = [OUT_VAR(c) variable];
    out->walkStrength = [self outputWalkStrength:c];
    out->stay = [self constantOutput:c];
    if (out->stay) {
        [constraint execute];
    }
}

-(int)outputWalkStrength:(Constraint)c
{
    register int outIndex, minStrength, m, mOutIndex;
    
    minStrength = c->strength;
    outIndex = c->methodOuts[c->whichMethod];
    for (m = c->methodCount - 1; m >= 0; m--) {
        mOutIndex = c->methodOuts[m];
        if ((mOutIndex != outIndex) &&
            (Weaker([c->variables[mOutIndex] variable]->walkStrength, minStrength))) {
            minStrength = [c->variables[mOutIndex] variable]->walkStrength;
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
            if (![c->variables[i] variable]->stay) return false;
        }
    }
    return true;
}

/******* Private: Miscellaneous *******/

static void Error(char *s)
{
    @throw [NSException exceptionWithName:@(s)  reason:@(s) userInfo:@{}];
//    printf("DeltaBlue.c error: %s.\n", s);
//    exit(-1);
}

-(void)newMark
{
    currentMark++;
}


-(DBConstraint*)nextDownstreamConstraintFrom:(NSMutableArray*)todo variable:(DBVariable*)variable
{
    NSArray * allC = [variable constraints];

    
    DBConstraint *determiningC = [variable determinedBy];
    DBConstraint *first = nil;
    
//    NSLog(@"all constraints: %@",allC);
    for ( DBConstraint *cur in allC) {
//        NSLog(@"cur constraint: %p",cur);
        if ( cur != determiningC && [cur isSatisfied]) {
            if ( !first ) {
                first=cur;
            } else {
                [todo addObject:cur];
            }
        }
    }
//    Constraint firstConstraint = [first constraint];
    
    if (first == NULL) {
        first = [todo removeFirst];
//        firstConstraint = (Constraint) List_RemoveFirst(todo);
//        NSLog(@"remove first: %p",firstConstraint);
    }
    return first;
}

-(DBVariable*)variableWithName:(NSString*)name intValue:(long)value
{
    DBVariable *v=[DBVariable variableWithName:name intValue:value];
    [self addVariable:v];
    return v;
}

-(DBVariable*)constantWithName:(NSString*)name intValue:(long)value
{
    DBVariable *v=[[[DBVariable alloc]  initConstantWithName:name intValue:value] autorelease];
    [self addVariable:v];
    return v;
}

-(DBConstraint*)constraintWithVariables:(NSArray*)vars strength:(int)newStrength
{
    return [DBConstraint constraintWithVariables:vars strength:newStrength];
}

-(void)dealloc
{
    [bindings release];
    [super dealloc];
}

@end
