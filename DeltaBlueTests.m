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
    DBConstraint *addC, *multC1, *divC;
    DBSolver *solver=[DBSolver new];

    celcius = [solver variableWithName:@"C" intValue:0];
    fahrenheit = [solver variableWithName:@"F" intValue:0];
    t1 = [solver variableWithName:@"t1" intValue:1];
    t2 = [solver variableWithName:@"t2" intValue:1];
    nine = [solver constantWithName:@"*const*" intValue: 9];
    five = [solver constantWithName:@"*const*" intValue: 5];
    thirtyTwo = [solver constantWithName:@"*const*" intValue: 32];
    
    [celcius print]; printf(" = ");
    [fahrenheit print]; printf("\n\n");
    

    multC1 = [celcius multiplyBy:nine into:t1 strength:S_required];
    divC = [t1 divideBy:five into:t2 strength:S_required];
    addC=[t2 add:thirtyTwo into:fahrenheit strength:S_required];
    
    [celcius assignInt:0];
    INTEXPECT([celcius intValue], 0, @"celcius for celcius 0");
    INTEXPECT([fahrenheit intValue], 32, @"fahrenheit for celcius 0");
    

    [fahrenheit assignInt:212];
    INTEXPECT([celcius intValue], 100, @"celcius for fahrenheit 212");
    INTEXPECT([fahrenheit intValue], 212, @"fahrenheit for fahrenheit 212");

    

    [celcius assignInt:-40];
    INTEXPECT([celcius intValue], -40, @"celcius for celcius -40");
    INTEXPECT([fahrenheit intValue], -40, @"fahrenheit for celcius -40");
    
    
 
    [fahrenheit assignInt:70];
    INTEXPECT([celcius intValue], 21, @"celcius for fahrenheit 70");
    INTEXPECT([fahrenheit intValue], 70, @"fahrenheit for fahrenheit 70");
    
}

+testSelectors
{
    return @[
            @"testTemperatureConverter",
            
             ];
}


@end
