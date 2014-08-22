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
idAccessor(externalReference, _setExternalReference )

idAccessor(localValue, _setLocalValue )
objectAccessor(NSString, name, setName)
scalarAccessor(Variable, variable , setVariable)

-(void)setExternalReference:(id)newVar
{
    if ( [externalReference respondsToSelector:@selector(setDelegate:)] ) {
        [externalReference setDelegate:nil];
    }
    [self _setExternalReference:newVar];
    if ( [newVar respondsToSelector:@selector(setDelegate:)] ) {
        [newVar setDelegate:self];
    }
}

-value
{
    return externalReference ? [externalReference value] : [self localValue];
}

-(void)_setValue:newValue
{
    externalReference ? [externalReference _setValue:newValue] : [self _setLocalValue:newValue];
}

-initConstantWithName:(NSString*)newName intValue:(long)newValue
{
    self=[super init];
    if ( self ) {
        [self setVariable:Variable_CreateConstant()];
        [self setName:name];
        [self _setIntValue:newValue];
    }
    return self;
}

-initWithName:(NSString*)name intValue:(long)newValue
{
    self=[super init];
    if ( self ) {
        variable=Variable_Create( );
        [self _setIntValue:newValue];

    }
    return self;
}


+variableWithName:(NSString*)name intValue:(long)value
{
    return [[[self alloc] initWithName:name intValue:value] autorelease];
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
    return [[self value] longValue];
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
    [self _setValue:newVar];
    [self resatisfy];
}



-(void)resatisfy
{
    Constraint	editC;
    NSArray*	plan;
    
    editC = EditC(self, S_required,solver);
    if (SATISFIED(editC)) {
        plan=[solver extractPlanFromConstraint:[DBConstraint constraintWithCConstraint:editC]];
        ExecutePlan(plan);
    }
    DestroyConstraint(editC);
}

-(void)changed:ref
{
    [self resatisfy];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"%@ = %@",name,[self value]];
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
