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


+(instancetype)constraintWithVariables:(NSArray*)newVars strength:(int)strength
{
    return [[[self alloc] initWithVariables:newVars strength:strength] autorelease];
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

-initWithVariables:(NSArray*)vars strength:(int)strength
{
    int numVars = [vars count];
    Constraint c=Constraint_Create( numVars, strength);
    if ( c ) {
        self=[self initWithCConstraint:c];
        for (int i=0;i<numVars;i++ ) {
            c->variables[i]=[vars objectAtIndex:i];
            c->methodOuts[i]=i;
        }
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
    constraint->methodCount = [[self methodBlocks] count];
}

-(DBVariable *)variableAtIndex:(int)anIndex
{
    return constraint->variables[anIndex];
}

-(void)add2ArgBlock:(TwoArgBlock)aBlock
{
    if ( constraint->varCount == 3 ) {
        int currentResultIndex = [[self methodBlocks] count];
        int args[3];
        for (int i=0,target =0;i<3;i++,target++) {
            if ( i==currentResultIndex) {
                target++;
            }
            args[i]=target;
        }
        int first=args[0];
        int second=args[1];
        [self addMethodBlock:^(DBConstraint *c) {
            id value1=[[c variableAtIndex:first] value];
            id value2=nil;[[c variableAtIndex:second] value];
            id result =aBlock( value1, value2);
            [[c variableAtIndex:currentResultIndex] _setValue:result];
        }];
    } else {
        NSLog(@"2arg block only makes sense with 3 vars");
    }
}

-(void)add1ArgBlock:(OneArgBlock)aBlock
{
    if ( constraint->varCount == 2 ) {
        int currentResultIndex = [[self methodBlocks] count];
        int args[2];
        for (int i=0,target =0;i<2;i++,target++) {
            if ( i==currentResultIndex) {
                target++;
            }
            args[i]=target;
        }
        int first=args[0];
        [self addMethodBlock:^(DBConstraint *c) {
            id value1=[[c variableAtIndex:first] value];
            id result =aBlock( value1);
            [[c variableAtIndex:currentResultIndex] _setValue:result];
        }];
    } else {
        NSLog(@"1arg block only makes sense with 2 vars");
    }
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
