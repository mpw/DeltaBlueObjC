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


-initConstantWithName:(NSString*)name value:(long)value
{
    self=[super init];
    if ( self ) {
        variable=Variable_CreateConstant( (char*)[name UTF8String], value);
        [[DBSolver solver] addVariable:self];
    }
    return self;
}

-initWithName:(NSString*)name value:(long)value
{
    self=[super init];
    if ( self ) {
        variable=Variable_Create( [name UTF8String], value);
        [[DBSolver solver] addVariable:self];
    }
    return self;
}


+variableWithName:(NSString*)name value:(long)value
{
    return [[[self alloc] initWithName:name value:value] autorelease];
}

-(Variable)variable
{
    return variable;
}

-(List)constraints
{
    return variable->constraints;
}

-(long)value
{
    return variable->value;
}

-(void)assign:(long)newValue
{
    Variable v=[self variable];
    Constraint	editC;
    List	plan;
    
    editC = EditC(v, S_required);
    if (SATISFIED(editC)) {
        v->value = newValue;
        plan=[[DBSolver solver] extractPlanFromConstraint:editC];
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
    return [DBConstraint constraintWithCConstraint:MultiplyC([self variable], [other variable], [result variable], strength)];
}


-(DBConstraint*)add:(DBVariable*)other into:(DBVariable*)result strength:(int)strength
{
    return [DBConstraint constraintWithCConstraint:AddC([self variable], [other variable], [result variable], strength)];
}



@end
