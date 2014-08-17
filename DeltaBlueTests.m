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
#import "DBSolver.h"

#include "List.h"
#include "Constraints.h"
#include "DeltaBlue.h"
#include "UsefulConstraints.h"


@implementation DeltaBlueTests



+(void)testTemperatureConverter
{
    DBVariable *celcius, *fahrenheit, *t1, *t2, *nine, *five, *thirtyTwo;
    DBConstraint *addC, *multC1, *multC2;
    DBSolver *solver=[DBSolver new];

    celcius = [solver variableWithName:@"C" value:0];
    fahrenheit = [solver variableWithName:@"F" value:0];
    t1 = [solver variableWithName:@"t1" value:1];
    t2 = [solver variableWithName:@"t2" value:1];
    nine = [solver constantWithName:@"*const*" value: 9];
    five = [solver constantWithName:@"*const*" value: 5];
    thirtyTwo = [solver constantWithName:@"*const*" value: 32];
    
    printf("Before adding constraints:\n  ");
    [celcius print]; printf(" = ");
    [fahrenheit print]; printf("\n\n");
    

    printf("will add c1:\n  ");
    multC1 = [celcius multiplyBy:nine into:t1 strength:S_required];
    printf("c1\n");
    multC2 = [t2 multiplyBy:five into:t1 strength:S_required];
    printf("c2\n");
    addC=[t2 add:thirtyTwo into:fahrenheit strength:S_required];
    printf("After adding constraints:\n  ");
   
    
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
