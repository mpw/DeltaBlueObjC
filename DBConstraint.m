//
//  DBConstraint.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import "DBConstraint.h"
#define SATISFIED(c)	((c)->whichMethod != NO_METHOD)

@implementation DBConstraint

+(instancetype)constraintWithCConstraint:(Constraint)aCConstraint;
{
    return [[[self alloc] initWithCConstraint:aCConstraint] autorelease];
}


-initWithCConstraint:(Constraint)aCConstraint
{
    if ( self=[super init] ) {
        constraint=aCConstraint;
    }
    return self;
}


-(Constraint)constraint
{
    return constraint;
}

-(NSUInteger)hash
{
    return (NSUInteger)constraint;
}

-(BOOL)isEqual:(id)object
{
    return constraint == [object constraint];
}

-(BOOL)isSatisfiedInput
{
    return (constraint->inputFlag && SATISFIED(constraint));
}

-(DBVariable*)outputVariable
{
    return (constraint->variables[constraint->methodOuts[constraint->whichMethod]]);
}

@end
