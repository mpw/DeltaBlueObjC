//
//  MPWConstraintFormula.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 06/06/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MPWConstraintFormula.h"
#import <ObjectiveSmalltalk/MPWExpression.h>
#import <MPWFoundation/AccessorMacros.h>


@implementation MPWConstraintFormula

idAccessor( source, setSource )
idAccessor( compiled, setCompiled )
//boolAccessor( evaluated, setEvaluated )


-initWithSource:aFormula compiled:aCompiledScript
{
	self = [super init];
	[self setSource:aFormula];
	[self setCompiled:aCompiledScript];
	return self;
}

+formulaWithSource:aFormula compiled:aCompiledScript
{
	return [[[self alloc] initWithSource:aFormula compiled:aCompiledScript] autorelease];
}


-evaluateIn:anEvaluator
{
	id value = [compiled evaluateIn:anEvaluator];
//	[anEvaluator markChanged:[compiled variablesWritten]];
	return value;
}

-variablesWritten
{
    return [compiled variablesWritten];
}

-sourceVariables
{
	return [compiled variablesRead];
}

-compileIn:compiler
{
	return self;
}

-(void)dealloc
{
	[compiled release];
	[source release];
	[super dealloc];
}

-copyWithZone:aZone
{
	return self;
}

-(int)isInterestedInVariables:(NSSet*)variables
{
	return [[self sourceVariables] intersectsSet:variables];
}

@end
