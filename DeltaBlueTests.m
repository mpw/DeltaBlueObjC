//
//  DeltaBlueTests.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import "DeltaBlueTests.h"

#import <MPWFoundation/MPWFoundation.h>
#import "DBVariable.h"
#import "DBConstraint.h"


#include "List.h"
#include "Constraints.h"
#include "DeltaBlue.h"
#include "UsefulConstraints.h"


@implementation DeltaBlueTests

/* This is how to assign to constrained variables. */
static void Assign(v, newValue)
Variable v;
long newValue;
{
    Constraint	editC;
    long 	msecs;
    List	plan;
    
    editC = EditC(v, S_required);
    if (SATISFIED(editC)) {
        v->value = newValue;
        plan = ExtractPlanFromConstraint(editC);
        ExecutePlan(plan);
        List_Destroy(plan);
    }
    DestroyConstraint(editC);
}


+(void)testTemperatureConverter
{
    DBVariable *celcius, *fahrenheit, *t1, *t2, *nine, *five, *thirtyTwo;
//    Variable celcius, fahrenheit, t1, t2, nine, five, thirtyTwo;
    DBConstraint *addC, *multC1, *multC2;
    
    InitDeltaBlue();
    celcius = [DBVariable variableWithName:@"C" value:0];
    fahrenheit = [DBVariable variableWithName:@"F" value:0];
    t1 = [DBVariable variableWithName:@"t1" value:1];
    t2 = [DBVariable variableWithName:@"t2" value:1];
    nine = [[[DBVariable alloc] initConstantWithName:@"*const*" value: 9] autorelease];
    five = [[[DBVariable alloc] initConstantWithName:@"*const*" value: 5] autorelease];
    thirtyTwo = [[[DBVariable alloc] initConstantWithName:@"*const*" value: 32] autorelease];
    
    printf("Before adding constraints:\n  ");
    [celcius print]; printf(" = ");
    [fahrenheit print]; printf("\n\n");
    
    printf("After adding constraints:\n  ");

    multC1 = [celcius multiplyBy:nine into:t1 strength:S_required];
//    multC1 = MultiplyC(celcius, nine, t1, S_required);
    multC1 = [t2 multiplyBy:five into:t1 strength:S_required];
//    multC2 = MultiplyC(t2, five, t1, S_required);
    addC=[t2 add:thirtyTwo into:fahrenheit strength:S_required];
    
//    addC = AddC(t2, thirtyTwo, fahrenheit, S_required);
    
    
    
//    Constraint_Print(multC1); printf("  ");
//    Constraint_Print(multC2); printf("  ");
//    Constraint_Print(addC); printf("  ");
//    Variable_Print(celcius); printf(" = ");
//    Variable_Print(fahrenheit); printf("\n\n");
    
    [celcius assign:0];
    INTEXPECT([celcius value], 0, @"celcius for celcius 0");
    INTEXPECT([fahrenheit value], 32, @"fahrenheit for celcius 0");
    
    printf("Changing fahrenheit to 212:\n  ");

    [fahrenheit assign:212];
    INTEXPECT([celcius value], 100, @"celcius for fahrenheit 212");
    INTEXPECT([fahrenheit value], 212, @"fahrenheit for fahrenheit 212");

    

    printf("Changing celcius to -40:\n  ");
    [celcius assign:-40];
    INTEXPECT([celcius value], -40, @"celcius for celcius -40");
    INTEXPECT([fahrenheit value], -40, @"fahrenheit for celcius -40");
    
    
    printf("Changing fahrenheit to 70:\n  ");
 
    [fahrenheit assign:70];
    INTEXPECT([celcius value], 21, @"celcius for fahrenheit 70");
    INTEXPECT([fahrenheit value], 70, @"fahrenheit for fahrenheit 70");
    

}

+testSelectors
{
    return @[
            @"testTemperatureConverter",
            
             ];
}


@end
