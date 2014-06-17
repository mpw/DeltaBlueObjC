//
//  MPWSimpleConstraintSolver.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 06/06/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWSimpleConstraintSolver.h"
#import "MPWConstraintFormula.h"

@implementation MPWSimpleConstraintSolver

objectAccessor( NSMutableArray*, formulae, setFormulae )
objectAccessor( NSMutableSet*, changedVariables, setChangedVariables )

+solver
{
	return [[[self alloc] init] autorelease];
}

-basicEvaluate:aScript
{
	return [super evaluate:aScript];
}

-evaluate:aScript
{
	id compiled = [self compile:aScript];
	id result = [self basicEvaluate:compiled];
	[self markChanged:[compiled variablesWritten]];
	[self reevaluateConstraints];
//	[self clearChanged];
	return result;
}

-(void)markChanged:(NSSet*)newChanged
{
	[changedVariables unionSet:newChanged];
}

-(void)evaluateIfNecessary:aFormula
{
	
	if ([[aFormula sourceVariables] intersectsSet:changedVariables] ) {
		[self basicEvaluate:aFormula];
	}
}

-(NSSet*)toEvalute
{
	//--- iterating through all the constraints each time
	//--- is inefficient (but works), better would be to
	//--- actually follow the dependency graph induced by
	//--- the dependencies in the constraints
	return [NSMutableSet setWithArray:[[[self formulae] select] isInterestedInVariables:changedVariables]];
}

-(void)reevaluateConstraints
{
	NSMutableSet *toEvaluate=nil;;
	NSMutableSet *evaluated=[NSMutableSet set];
	NSMutableSet *affectedVariables = [NSMutableSet set];
	NSMutableSet *allAffectedVarialbes = [NSMutableSet set];
	while(1) {
		//--- compute all the constraints that need to be
		//--- recomputed due to to the changes so far
		id newToEvaluate =[self toEvalute];
		//--- but without any that have already been computed
		//--- this time around
		[newToEvaluate minusSet:evaluated];
		//--- reset changed variables
		[self setChangedVariables:[NSMutableSet set]];
		//--- if there is work left to to (constraints to evaluate)
		if ( [newToEvaluate count] > 0 ) {
			//--- evaluate the constraints
			[[self do] basicEvaluate:[newToEvaluate each]];
			//--- and note that we have done so, so we
			//--- don't evaluate them again
			[evaluated unionSet:newToEvaluate];
			//--- remember all the variables that were affected
			//--- (we want to return them at the end
			[affectedVariables unionSet:changedVariables];
		} else {
			break;
		}
	}
	//--- 'return' the variables we changed during
	//--- constraint evaluation
	[self setChangedVariables:affectedVariables];

}

-init
{
	self=[super init];
	[self setFormulae:[NSMutableArray array]];
	[self setChangedVariables:[NSMutableSet set]];
	return self;
}

-(void)addFormula:aFormula
{
	id compiledFormula = [self compile:aFormula];
	[[self formulae] addObject:[MPWConstraintFormula formulaWithSource:aFormula compiled:compiledFormula]];
}

@end

@implementation MPWSimpleConstraintSolver(testing)

+(void)testSimpleConstraintUpdate
{
	id solver = [self solver];
	[solver addFormula:@"a := b + c"];
	[solver addFormula:@"d := b * c"];
	[solver evaluate:@"b:=2. c:=3."];
	INTEXPECT( [[solver valueOfVariableNamed:@"a"] intValue], 5 ,@"constraint automatically evaluated");
	INTEXPECT( [[solver valueOfVariableNamed:@"d"] intValue], 6 ,@"multiple constraints automatically evaluated");
}

+(void)testChangeMarking
{
	id expectedChanged = [NSSet setWithObjects:@"a",@"d",nil];
	id solver = [self solver];
	[solver addFormula:@"a := b + 1"];
	[solver addFormula:@"d := b * 4"];
	[solver evaluate:@"b:=2."];
	IDEXPECT( [solver changedVariables],expectedChanged , @"dependents should have changed");

}

+(void)testOnlyRelevantAreChanged
{
	id expectedChanged = [NSSet setWithObjects:@"a",nil];		// 'd' is not here!
	id solver = [self solver];
	[solver addFormula:@"a := b + c"];
	[solver addFormula:@"d := e * f"];
	[solver evaluate:@"b:=2. c:=3."];
	IDEXPECT( [solver changedVariables],expectedChanged , @"dependents should have changed");
}

+(void)testIndirectDependentAreUpdated
{
	id expectedChanged = [NSSet setWithObjects:@"a",@"d",nil];
	id solver = [self solver];
	[solver addFormula:@"a := b + 1"];
	[solver addFormula:@"d := a * 2"];
	[solver evaluate:@"b:=2."];
	IDEXPECT( [solver changedVariables],expectedChanged , @"indirect dependents should have changed");
	INTEXPECT( [[solver valueOfVariableNamed:@"d"] intValue], 6 ,@"indirect constraints evaluate correctly");
}

+(void)testOrderRelevantConstraintUpdate
{
	id expectedChanged = [NSSet setWithObjects:@"a",@"d",nil];
	id solver = [self solver];
	[solver addFormula:@"a := d + 2"];
	[solver addFormula:@"d := b * 3"];
	[solver evaluate:@"b:=2."];
	IDEXPECT( [solver changedVariables],expectedChanged , @"indirect dependents should have changed");
	INTEXPECT( [[solver valueOfVariableNamed:@"a"] intValue], 8 ,@"dependent constraint automatically evaluated");
}

+(void)testCyclicConstraints
{
	id expectedChanged = [NSSet setWithObjects:@"c",@"f",nil];
	id solver = [self solver];
	[solver addFormula:@"f := c + 32."];
	[solver addFormula:@"c := f - 32"];
	[solver evaluate:@"f:=10."];
	IDEXPECT( [solver changedVariables],expectedChanged , @"cyclic should not evaluate inverse constraint");
	INTEXPECT( [[solver valueOfVariableNamed:@"c"] intValue], -22 ,@"cyclic constraint target");
	INTEXPECT( [[solver valueOfVariableNamed:@"f"] intValue], 10 ,@"cyclic constraint source");
}

+(void)testNonNumericConstraint
{
	id solver = [self solver];
	[solver addFormula:@"fullName := (firstName stringByAppendingString:' ') stringByAppendingString:lastName."];
	[solver evaluate:@"lastName := 'Weiher'. firstName := 'Marcel'."];
	IDEXPECT( [solver valueOfVariableNamed:@"fullName"], @"Marcel Weiher" ,@"string constraint");
	[solver evaluate:@"firstName := 'John'."];
	IDEXPECT( [solver valueOfVariableNamed:@"fullName"] , @"John Weiher" ,@"changed string constraint");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testSimpleConstraintUpdate",
		@"testChangeMarking",
		@"testOnlyRelevantAreChanged",
		@"testIndirectDependentAreUpdated",
		@"testOrderRelevantConstraintUpdate",
		@"testCyclicConstraints",
		@"testNonNumericConstraint",
		nil
		];
}

@end

