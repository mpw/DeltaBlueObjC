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
#import "DBSolver+Bindings.h"

#include "List.h"
#include "Constraints.h"
#include "DeltaBlue.h"
#include "UsefulConstraints.h"

#import <ObjectiveSmalltalk/MPWStCompiler.h>
#import <ObjectiveSmalltalk/MPWBinding.h>
#import "MPWDataflowConstraintExpression+SolverIntegration.h"

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

#define dbvar(i) ([(c) variableAtIndex:(i)])


static DBConstraint* create_Concat(DBVariable * prefix, DBVariable * suffix, DBVariable * combined, int strength, DBSolver *solver)
{
    DBConstraint *dbConstraint = [DBConstraint constraintWithVariables:@[ combined, prefix, suffix] strength:strength];
    [dbConstraint addMethodBlock:^(DBConstraint *c) {
        [dbvar(0) _setValue:[[dbvar(1) value  ]stringByAppendingString:[dbvar(2) value]]];
    }];
    [solver addConstraint:dbConstraint];
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

+(void)testSimpleObjSTConstraint
{
    DBSolver *solver=[DBSolver solver];
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"a := 2."];
    [compiler evaluateScriptString:@"b := 10."];
    
    id block=[compiler evaluateScriptString:@"[ b := a*20 + 1 ]"];
    DBConstraint *constraint=[solver constraintWithSTBlock:block inContext:compiler];
    [constraint add1ArgBlock:[compiler evaluateScriptString:@"[ :arg | arg - 1 /20]"]];
    [compiler evaluateScriptString:@" a:=200"];
    IDEXPECT([compiler evaluateScriptString:@"b"], @(4001), @"b forward-evaluated via constraint");
    [compiler evaluateScriptString:@" b:=1000"];
    IDEXPECT([compiler evaluateScriptString:@"a"], @(49.95), @"a backward-evaluated via constraint");
}

+(void)testTemperatureConverterObjST
{
    DBSolver *solver=[DBSolver solver];
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler evaluateScriptString:@"c := 0."];
    [compiler evaluateScriptString:@"f := 32."];
    [compiler evaluateScriptString:@"k := 100."];
    MPWBinding *c=[compiler evaluateScriptString:@"ref:c"];
    MPWBinding *f=[compiler evaluateScriptString:@"ref:f"];
    MPWBinding *k=[compiler evaluateScriptString:@"ref:k"];
    id block1=[compiler evaluateScriptString:@"[ f := c * (9.0/5) + 32 ]"];
    DBConstraint *fc_constraint=[solver constraintWithSTBlock:block1 inContext:compiler];
    [fc_constraint add1ArgBlock:[compiler evaluateScriptString:@"[ :farg | farg - 32.0 * (5.0/9)]"]];
    id block2=[compiler evaluateScriptString:@"[ k := c + 272 ]"];
    DBConstraint *ck_constraint=[solver constraintWithSTBlock:block2 inContext:compiler];
    [ck_constraint add1ArgBlock:[compiler evaluateScriptString:@"[ :farg | farg - 272 ]"]];

    
    [c bindValue:@(0)];
    IDEXPECT([f value], @(32), @"0 degrees C as F");
    [c bindValue:@(22)];
    IDEXPECT([f value], @(71.6), @"22 degrees C as F");
    [c bindValue:@(100)];
    IDEXPECT([f value], @(212), @"100 degrees C as F");
    [f bindValue:@(-40)];
    IDEXPECT([c value], @(-40), @"-40 degrees F as C");
    [f bindValue:@(212)];
    IDEXPECT([c value], @(100), @"212 degrees F as C");
    [f bindValue:@(32)];
    IDEXPECT([c value], @(0), @"32 degrees F as C");
    IDEXPECT([k value], @(272), @"32 degrees F as K");
    [f bindValue:@(212)];
    IDEXPECT([k value], @(372), @"212 degrees F as K");
}

+(MPWStCompiler*)compilerWithSolver
{
    DBSolver *solver=[DBSolver solver];
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler setSolver:solver];
    return compiler;
}

+(void)testTwoArgBlock
{
    MPWStCompiler *compiler=[self compilerWithSolver];

    [compiler evaluateScriptString:@"a := 5."];
    [compiler evaluateScriptString:@"b := 15."];
    [compiler evaluateScriptString:@"c := 20."];
    MPWBinding *a=[compiler evaluateScriptString:@"ref:a"];
    MPWBinding *b=[compiler evaluateScriptString:@"ref:b"];
    MPWBinding *c=[compiler evaluateScriptString:@"ref:c"];
    id block1=[compiler evaluateScriptString:@"[  c := a + b ]"];
    DBConstraint *abc_add_constraint=[[compiler solver] constraintWithSTBlock:block1 inContext:compiler];
    [a bindValue:@(10)];
    IDEXPECT([c value], @(25), @"10 + 15");
    [b bindValue:@(107)];
    IDEXPECT([c value], @(117), @"10 + 107");
}

+(void)testDataflowConstraintConnector
{
    MPWStCompiler *compiler=[self compilerWithSolver];

    [compiler evaluateScriptString:@"a := 5."];
    [compiler evaluateScriptString:@"b := 15."];
    [compiler evaluateScriptString:@"c := 20."];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"c"] intValue], 20, @"before");
    [compiler evaluateScriptString:@"c |= a + b."];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"c"] intValue], 20, @"after same value");
    [compiler evaluateScriptString:@"a := 20."];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"c"] intValue], 35, @"after new value");
    
}

+(void)testBidirectionalDataflowConstraintConnector
{
    MPWStCompiler *compiler=[self compilerWithSolver];

    [compiler evaluateScriptString:@"a := 15."];
    [compiler evaluateScriptString:@"b := 15."];
    [compiler evaluateScriptString:@"b =|= a."];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"b"] intValue], 15, @"before");

    [compiler evaluateScriptString:@"a := 20"];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"b"] intValue], 20, @"direction a -> b");

    [compiler evaluateScriptString:@"b := 10"];

 INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"a"] intValue], 10, @"direction b -> a");

    
}

+(void)testConstraintWithMultipleFormuaeWithoutSpecialBlock
{
    MPWStCompiler *compiler=[self compilerWithSolver];

    [compiler evaluateScriptString:@"a := 5."];
    [compiler evaluateScriptString:@"b := 15."];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"b"] intValue], 15, @"before");
    [compiler evaluateScriptString:@"b |= a + 10."];
    [compiler evaluateScriptString:@"a |= b - 10."];
    [compiler evaluateScriptString:@"a := 20. "];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"b"] intValue], 30, @"after forward formula");
    [compiler evaluateScriptString:@"b := 50."];
    INTEXPECT([(NSNumber*)[compiler evaluateScriptString:@"a"] intValue], 40, @"after reverse formula");
    
}


+(void)testFormulaOfSameConstraintCanBeIDentified
{
    MPWStCompiler *compiler=[self compilerWithSolver];

    [compiler evaluateScriptString:@"a := 5. b:=15. c:=45. "];
    DBConstraint *c1 = [compiler evaluateScriptString:@"b |= a + 10."];
    DBConstraint *c2 = [compiler evaluateScriptString:@"a |= b - 10."];
    DBConstraint *c3 = [compiler evaluateScriptString:@"c |= b + 30."];
    DBConstraint *c4 = [compiler evaluateScriptString:@"b |= c - 30."];
    EXPECTTRUE([c1 hasSameVariablesAs:c2], @"hasSameVariables");
    EXPECTTRUE([c2 hasSameVariablesAs:c1], @"hasSameVariables");
    EXPECTFALSE([c1 hasSameVariablesAs:c3], @"hasSameVariables");
    EXPECTFALSE([c2 hasSameVariablesAs:c3], @"hasSameVariables");
    EXPECTTRUE([c4 hasSameVariablesAs:c3], @"hasSameVariables");
}

+(void)testGetConstraintWithSameVariablesAsLastAdded
{
    MPWStCompiler *compiler=[self compilerWithSolver];
    [compiler evaluateScriptString:@"a := 5. b:=15."];
    DBConstraint *c1 = [compiler evaluateScriptString:@"b |= a + 10."];
    MPWDataflowConstraintExpression *expr=[compiler compile:@"a |= b - 10"];
    DBConstraint *lookup=[[compiler solver] lookupConstraintWithLhs:[expr lhs] rhs:[expr rhs] inContext:compiler ];
    EXPECTTRUE( lookup==c1, @"should have found");
}


+testSelectors
{
    return @[
             @"testTemperatureConverter",
             @"testStringAppend",
             @"testSimpleObjSTConstraint",
             @"testTemperatureConverterObjST",
             @"testTwoArgBlock",
             @"testDataflowConstraintConnector",
             @"testBidirectionalDataflowConstraintConnector",
             @"testFormulaOfSameConstraintCanBeIDentified",
             @"testGetConstraintWithSameVariablesAsLastAdded",
             @"testConstraintWithMultipleFormuaeWithoutSpecialBlock",
             ];
}


@end
