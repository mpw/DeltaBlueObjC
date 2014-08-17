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


-initConstantWithName:(NSString*)name intValue:(long)value
{
    self=[super init];
    if ( self ) {
        variable=Variable_CreateConstant( (char*)[name UTF8String], value);
    }
    return self;
}

-initWithName:(NSString*)name intValue:(long)value
{
    self=[super init];
    if ( self ) {
        variable=Variable_Create( (char*)[name UTF8String], value);
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

-(long)intValue
{
    return variable->value;
}

-(void)assignInt:(long)newValue
{
    Variable v=[self variable];
    Constraint	editC;
    List	plan;
    
    editC = EditC(v, S_required,solver);
    if (SATISFIED(editC)) {
        v->value = newValue;
        plan=[solver extractPlanFromConstraint:editC];
        ExecutePlan(plan);
        List_Destroy(plan);
    }
    DestroyConstraint(editC);
}


-(void)print
{
    Variable_Print(variable);
}

-(DBConstraint*)multiplyBy:(DBVariable*)other into:(DBVariable*)result strength:(int)strength
{
    return [DBConstraint constraintWithCConstraint:MultiplyC([self variable], [other variable], [result variable], strength, solver)];
}


-(DBConstraint*)add:(DBVariable*)other into:(DBVariable*)result strength:(int)strength
{
    return [DBConstraint constraintWithCConstraint:AddC([self variable], [other variable], [result variable], strength, solver)];
}



@end
