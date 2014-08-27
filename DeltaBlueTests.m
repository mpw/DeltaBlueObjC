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
    
    NSLog(@"%@ = %@",celcius,fahrenheit);
    

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

#define var(i) (c->variables[i])
#define dbvar(i) ([(c) variableAtIndex:(i)])


static void concat_Execute(Constraint c)
{
    /* (src * scale) + offset = dest */
    NSLog(@"satisfy concat: %@ %@ %@ method: %d",var(0),var(1),var(2),c->whichMethod);
    switch (c->whichMethod) {
        case 0:
            [var(0) _setValue:[[var(1) value  ]stringByAppendingString:[var(2) value]]];
            break;
        case 1:
            [var(1) _setValue:[[var(0) value] substringFromIndex:[[var(2) value] length]]];
            
            break;
        case 2:
            [var(2) _setValue:[[var(0) value] substringToIndex:[[var(1) value] length]]];
            break;
    }
}




static DBConstraint* create_Concat(DBVariable * prefix, DBVariable * suffix, DBVariable * combined, int strength, DBSolver *solver)
{
    Constraint new = Constraint_Create(3, strength);
//    new->execute = concat_Execute;
    new->variables[0] = combined;
    new->variables[1] = prefix;
    new->variables[2] = suffix;
    new->methodCount = 1;
    new->methodOuts[0] = 0;
    new->methodOuts[1] = 1;
    new->methodOuts[2] = 2;
    DBConstraint *dbConstraint = [DBConstraint constraintWithCConstraint:new];
    [dbConstraint addMethodBlock:^(DBConstraint *c) {
        [dbvar(0) _setValue:[[dbvar(1) value  ]stringByAppendingString:[dbvar(2) value]]];
    }];
    [solver addConstraint:new];
    return dbConstraint;
};


+(void)testStringAppend
{
    DBVariable *prefix, *suffix, *combined;
    DBConstraint *concat;
    DBSolver *solver=[DBSolver new];

    prefix=[solver variableWithName:@"prefix" intValue:0];
    suffix=[solver variableWithName:@"suffix" intValue:0];
    combined=[solver variableWithName:@"combined" intValue:0];
    [prefix _setValue:@"Hello "];
    [suffix _setValue:@"World!"];
    [combined _setValue:@" "];
    concat = create_Concat( prefix,suffix,combined, S_required,solver);
    [prefix _setValue:@"Hello "];
    [suffix _setValue:@"World!"];
    
    [prefix setValue:@"Hello cruel "];
    
    IDEXPECT([combined value], @"Hello cruel World!", @"concated");
    
    
    [suffix setValue:@"Moon?"];
    
    IDEXPECT([combined value], @"Hello cruel Moon?", @"concated");
    
    
//    [combined setValue:@"Hello cruel Sun"];
    
//    IDEXPECT([prefix value], @"Hello cruel ", @"prefix");
    
    
    
}



+testSelectors
{
    return @[
             @"testTemperatureConverter",
             @"testStringAppend",
            
             ];
}


@end
