//
//  DBVariable.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import "DBVariable.h"
#import "UsefulConstraints.h"
#import "DBConstraint.h"
#import "DeltaBlue.h"
#import "DBSolver.h"

@implementation DBVariable

scalarAccessor(id, solver,setSolver)

idAccessor(value, _setValue )


-initConstantWithName:(NSString*)name intValue:(long)newValue
{
    self=[super init];
    if ( self ) {
        variable=Variable_CreateConstant( (char*)[name UTF8String]);
        [self _setIntValue:newValue];
    }
    return self;
}

-initWithName:(NSString*)name intValue:(long)newValue
{
    self=[super init];
    if ( self ) {
        variable=Variable_Create( (char*)[name UTF8String]);
        [self _setIntValue:newValue];

    }
    return self;
}


+variableWithName:(NSString*)name intValue:(long)value
{
    return [[[self alloc] initWithName:name intValue:value] autorelease];
}

-(Variable)variable
{
    return variable;
}

-(NSMutableArray*)constraints
{
    return variable->constraints;
}

-(void)addConstraint:(DBConstraint*)newConstraint
{
    [[self constraints] addObject:newConstraint];
}


-(BOOL)isKnownWithMark:(long)mark
{
    return
            variable->mark == mark ||
            variable->stay ||
    variable->determinedBy == nil;
    
}

-(void)removeConstraint:(DBConstraint*)oldConstraint
{
    [[self constraints] removeObject:oldConstraint];
}

-(long)intValue
{
    return [value longValue];
}

-(void)_setIntValue:(long)newValue
{
    [self _setValue:@(newValue)];
}

-(void)assignInt:(long)newValue
{
    [self setValue:@(newValue)];
}

-(void)setValue:(id)newVar
{
    Constraint	editC;
    NSArray*	plan;
    
    editC = EditC(self, S_required,solver);
    if (SATISFIED(editC)) {
        [self _setValue:newVar];
        plan=[solver extractPlanFromConstraint:[DBConstraint constraintWithCConstraint:editC]];
        ExecutePlan(plan);
    }
    DestroyConstraint(editC);
}



-(NSString*)description
{
    return [NSString stringWithFormat:@"%s = %@",variable->name,value];
}

-(DBConstraint*)multiplyBy:(DBVariable*)other into:(DBVariable*)result strength:(int)strength
{
    return [DBConstraint constraintWithCConstraint:MultiplyC(self, other, result, strength, solver)];
}

-(DBConstraint*)divideBy:(DBVariable*)other into:(DBVariable*)result strength:(int)strength
{
    return [DBConstraint constraintWithCConstraint:DivideC(self, other, result, strength, solver)];
}


-(DBConstraint*)add:(DBVariable*)other into:(DBVariable*)result strength:(int)strength
{
    return [DBConstraint constraintWithCConstraint:AddC(self, other, result, strength, solver)];
}

-(long)mark { return variable->mark; }

-(void)setMark:(long)newVar {
    variable->mark=newVar;
}


@end
