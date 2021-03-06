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
objectAccessor(DBConstraint, lastAdded, setLastAdded)
objectAccessor(NSMutableOrderedSet, allConstraints, setAllConstraints)
objectAccessor(NSMutableArray, unsatisfied, setUnsatisfied)
boolAccessor(solving, setSolving)
intAccessor( strength, setStrength )
intAccessor( currentMark, setCurrentMark )

+(instancetype)sharedSolver
{
    static DBSolver *solver=nil;
    if ( !solver ) {
        solver=[self new];
    }
    return solver;
}

+(instancetype)solver
{
    return [[self new] autorelease];
}

-(void)initDeltaBlue
{
    allVariables=[NSMutableArray new];
    hot = [NSMutableArray new];
    todo1 = [NSMutableArray new];
    todo2 = [NSMutableArray new];
    allConstraints = [NSMutableOrderedSet new];
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

/******** Public: Variables and Constraints *******/

-(void)addVariable:(DBVariable*)v
{
    [allVariables addObject:v];
    [v setSolver:self];
}


-(void)destroyVariable:(DBVariable*)theVar
{

    [self withArray:[theVar constraints] do:@selector(destroyConstraint:)];
    [allVariables removeObject:theVar];
}

-(void)addConstraint:(DBConstraint*)c
{
//    NSLog(@"addConstraint: %@",c);
    [[self allConstraints] addObject:c];
    [self setLastAdded:c];
    [c prepareForAdd];
    [self incrementalAdd:c];
//    NSLog(@"did addConstraint, all constraints: %@",allConstraints);
}


-(void)destroyConstraint:(DBConstraint*)c
{
//    if ( [c isSatisfied]) {
        [self incrementalRemoveObj:c];
//    }
    [[self allConstraints] removeObject:c];
    [c destroy];
}

/******** Public: Plan Extraction *******/


-(void)addIfSatisfiedInputObj:(DBConstraint*)c
{
    if ( [c isSatisfiedInput]) {
        [hot addObject:c];
    }
}


-(void)withArray:(NSArray*)aList do:(SEL)selector
{
    for ( id obj in aList) {
        [self performSelector:selector withObject:obj];
    }
}



-(void)collectSatisfiedInputs:(DBVariable*)theVar
{
    [self withArray:[theVar constraints] do:@selector(addIfSatisfiedInputObj:)];
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
        
        if (([out mark] != currentMark) && [nextC inputsKnownWithMark:currentMark]) {
            [plan addObject:nextC];
            [out setMark:currentMark];
            nextC = [self nextDownstreamConstraintFrom:hot variable:out];
        } else {
            nextC = [hot removeFirst];
        }
    }
    return plan;
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
    @try {
        if (solving) {
//            NSLog(@"=== already solving!! ====");
        }
        solving=YES;
        DBConstraint	*overridden=nil;
        DBVariable	*outVar;
        
        [constraint chooseMethodWithMark:currentMark];
        
        if ( [constraint isSatisfied]) {
            
            [constraint markInputs:currentMark];
            
            outVar =  [constraint outputVariable];
            overridden = [outVar determinedBy];
            if (overridden != nil) {
                [overridden clearMethod];
            }
            [outVar setDeterminedBy:constraint];
            
            if (![self addPropagate:constraint]) {
                Error("Cycle encountered");
                solving=NO;
                return NULL;
            }
            [outVar setMark:currentMark];
            return overridden;
        } else {
            NSAssert5([constraint strength] != S_required, @"required constraint %@ not satisfied vars: %@  hot: %@  todo1: %@ todo2:%@",
                      constraint,allVariables,hot,todo1,todo2);
            //        if (c->strength == S_required) {
            //            Error("Could not satisfy a required constraint");
            //        }
            solving=NO;
            return nil;
        }
    } @finally {
        solving=NO;
    }
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
        if ([out mark] == currentMark) {
            /* remove the cycle-causing constraint */
//            NSLog(@"remove: %p",c);
            [self incrementalRemoveObj:c];
            return false;
        }
        [nextC recalculate];
//        [self recalculate:nextC];
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
        [unsatisfied addObject:constr];
    }
}


-(void)incrementalRemoveObj:(DBConstraint*)objConstraint
{
    //    NSLog(@"remove %p",c);
    @autoreleasepool {
        DBVariable *outputVar;
        
        outputVar = [objConstraint outputVariable];
        [objConstraint clearMethod];
        
        [objConstraint destroy];
        
        [self setUnsatisfied:[NSMutableArray array]];
        [self removePropagateFrom:outputVar];
        for (strength = S_required; strength <= S_weakest; strength++) {
            [self withArray:unsatisfied do:@selector(addConstraintAtStrength:)];
            
        }
        [self setUnsatisfied:nil];
        
    }
//    Variable out;
}


-(void)removePropagateFrom:(DBVariable*)v
{
    [todo2 removeAllObjects];
    [v setDeterminedBy:nil];
    
    [v setWalkStrength:S_weakest];
    [v setStay:YES];
    while (true) {
        DBConstraint	*nextC;
        
        [self withArray:[v constraints] do:@selector(collectUnsatisfied:)];

        
//        List_Do(v->constraints, CollectUnsatisfied);
        nextC = [self nextDownstreamConstraintFrom:todo2 variable:v];
//        NextDownstreamConstraint(todo2, v);
        if (nextC == NULL) {
            break;
        } else {
            [nextC recalculate];
//            [self recalculate:nextC];
            v = [nextC outputVariable];
        }
    }
}

/******* Private: Recalculation *******/

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
    
    if (first == NULL) {
        first = [todo removeFirst];
    }
    return first;
}

//---- creating constraints and variables


-(DBVariable*)variableWithName:(NSString*)name intValue:(long)value
{
    DBVariable *v=[DBVariable variableWithName:name intValue:value];
    [v setWalkStrength:3];
    [self addVariable:v];
    return v;
}

-(DBVariable*)constantWithName:(NSString*)name intValue:(long)value
{
    DBVariable *v=[[[DBVariable alloc]  initConstantWithName:name intValue:value] autorelease];
//    [v setWalkStrength:3];
    [self addVariable:v];
    return v;
}

-(DBConstraint*)constraintWithVariables:(NSArray*)vars strength:(int)newStrength
{
    return [DBConstraint constraintWithVariables:vars strength:newStrength];
}

-(DBConstraint*)lastConstraint
{
    return nil;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: strength: %d number unsatisfied: %d solving: %d hot: %d todo1: %d todo2: %d             \n\nconstraints: %@\n\nbindings: %@\n\nvariables: %@\ncurrentMark: %ld >",[self class],self,
            strength,
            (int)[unsatisfied count],solving,
            (int)[hot count],(int)[todo1 count],(int)[todo2 count],
            [self allConstraints],[self bindings],allVariables,
            currentMark
            ];
}


-(void)debugDump
{
    NSLog(@"solver: %@",self);
}

-(void)dealloc
{
    [bindings release];
    [super dealloc];
}

@end
