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
        // can't initialize methodBlocks here because we still
        // create temporary DBConstraint objects refering to
        // an underlying constraint struct
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

-(NSMutableArray*)methodBlocks
{
    return constraint->methodBlocks;
}

-(void)addMethodBlock:(ConstraintBlock)aBlock
{
    [[self methodBlocks] addObject:[aBlock copy]];
}

-(DBVariable *)variableAtIndex:(int)anIndex
{
    return constraint->variables[anIndex];
}

-(void)execute
{
    int whichMethod = constraint->whichMethod;
    if ( whichMethod < [[self methodBlocks] count]) {
        ConstraintBlock block = [[self methodBlocks] objectAtIndex:whichMethod];
        if ( block ) {
            block( self );
        }
    } else {
        if ( constraint->execute) {
            constraint->execute( constraint);
        }
    }
}


@end
