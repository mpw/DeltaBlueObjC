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
//scalarAccessor(Variable, variable , setVariable)

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
        variable=Variable_CreateConstant();
        [self setName:name];
        [self _setIntValue:newValue];
    }
    return self;
}

-initWithName:(NSString*)newName intValue:(long)newValue
{
    self=[super init];
    if ( self ) {
        variable=Variable_Create( );
        [self _setIntValue:newValue];
        [self setName:newName];
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
    [self determinedBy] == nil;
    
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
    if ( solver && ![solver solving]) {
//        NSLog(@"resatisfy, solver %@ is not solving (%d)",solver,[solver solving]);
        [solver setSolving:YES];
        Constraint	editC;
        NSArray*	plan;
        editC = EditC(self, S_preferred,solver);
        DBConstraint *c=[DBConstraint constraintWithCConstraint:editC];
        [solver setSolving:YES];
        if ([c isSatisfied]) {
            [solver setSolving:YES];
            plan=[solver extractPlanFromConstraint:c];
            [solver setSolving:YES];
            ExecutePlan(plan);
        }
        NSLog(@"will destroy temp constraint, number of constraints: %d",[solver allConstraints].count);
        [solver destroyConstraint:c];
        NSLog(@"did destroy temp constraint, number of constraints: %d",[solver allConstraints].count);
        [solver setSolving:NO];
    } else {
    }
}

-(void)changed:ref
{
    NSLog(@"changed: %@: %@",self,ref);
    [self resatisfy];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@ %p:%@ = %@, determinedBy: %p mark: %ld walkStrength: %d",[self class],self,name,[self value],determinedBy,variable->mark,variable->walkStrength];
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

-(DBConstraint *)constraintWith:(DBVariable *)other
{
    return [solver constraintWithVariables:@[ other, self] strength:0];
}

objectAccessor( DBConstraint, determinedBy, setDeterminedBy )

-(int)walkStrength
{
    return variable->walkStrength;
}

-(void)setWalkStrength:(int)newVar
{
    variable->walkStrength=newVar;
}

-(BOOL)stay
{
    return variable->stay;
}

-(void)setStay:(BOOL)newVar
{
    variable->stay=newVar;
}

@end
