//
//  DBSolver+Bindings.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/28/14.
//
//

#import "DBSolver+Bindings.h"
#import <ObjectiveSmalltalk/MPWBinding.h>
#import "DBVariable.h"
#import "DBConstraint.h"
#import <ObjectiveSmalltalk/MPWAssignmentExpression.h>
#import <ObjectiveSmalltalk/MPWBlockExpression.h>
#import <ObjectiveSmalltalk/MPWBlockContext.h>
#import <ObjectiveSmalltalk/MPWStatementList.h>

@implementation DBSolver (Bindings)

-(DBVariable*)lookupDBVariableWithBinding:(MPWBinding*)binding
{
    for ( DBVariable *var in allVariables) {
        id other=[var externalReference];
        BOOL isSame = other == binding;
        BOOL isEqual = [other isEqual: binding];
        if (  isSame  ) {
            return var;
        }
    }
    return nil;
}


-(DBVariable*)constraintVarWithBinding:(MPWBinding*)aBinding
{
    DBVariable *var=[self lookupDBVariableWithBinding:aBinding];
    if (!var && ![[aBinding name] isEqualTo:@"self"]) {
        var=[self variableWithName:[aBinding name] intValue:0];
        [var setExternalReference:aBinding];
        [var setWalkStrength:3];
    }
    return var;
}


-(DBConstraint *)constraintWithRef:(MPWBinding *)ref1 andRef:(MPWBinding *)ref2
{
    DBVariable *v1 = [self constraintVarWithBinding:ref1];
    DBVariable *v2 = [self constraintVarWithBinding:ref2];
    return [v1 constraintWith:v2];
}

-(MPWBlockInvocable*)convertRHSToBlock:(MPWExpression*)rhs inContext:aContext
{
    NSMutableSet *variableNamesRead = [[[rhs variableNamesRead] mutableCopy] autorelease];
    [variableNamesRead removeObject:@"self"];
//    NSString* arg=[[variableNamesRead allObjects] firstObject];
    MPWStatementList *newStatements = [MPWStatementList statementList];
    [newStatements addStatement:rhs];
    
    
    
    MPWBlockExpression *newBlock = [MPWBlockExpression blockWithStatements:newStatements arguments:[variableNamesRead allObjects]];
    MPWBlockContext *b = [MPWBlockContext blockContextWithBlock:newBlock context:aContext];
//    NSLog(@"converted block: %@",b);
//    NSLog(@"rhs: %@",rhs);
    return b;
}

-(NSArray*)bindingsForLhs:(MPWExpression*)lhs rhs:(MPWExpression*)rhs inContext:aContext
{
    MPWBinding *written = [[lhs identifier] bindingWithContext:aContext];
    NSArray *read=[[[[rhs variablesRead] allObjects] collect] bindingWithContext:aContext];
    NSArray *bindings = [@[written] arrayByAddingObjectsFromArray:read];
    return bindings;
}

-(NSArray*)constraintVarsForBindings:(NSArray*)thisConstraintBindings
{
    NSMutableArray *constraintVars=[NSMutableArray array];
    for ( MPWBinding *binding in thisConstraintBindings) {
        DBVariable* cvar=[self constraintVarWithBinding:binding];
        if ( cvar) {
            [constraintVars addObject:cvar];
            [cvar setWalkStrength:3];
            [binding startObserving];
        }
    }
    return constraintVars;
}

-(DBConstraint*)lookupConstraintWithLhs:(MPWExpression*)lhs rhs:(MPWExpression*)rhs inContext:aContext
{
    NSArray *bindingsArray = [self bindingsForLhs:lhs rhs:rhs inContext:aContext];
//    NSLog(@"bindingsArray: %@",bindingsArray);
    NSArray *variableArray = [self constraintVarsForBindings:bindingsArray];
//    NSLog(@"variableArray: %@",variableArray);
    NSSet *newVars = [NSSet setWithArray:variableArray];
//    NSLog(@"newVars (set): %@",newVars);
    if ( [[self lastAdded] hasVariables:newVars]) {
        return [self lastAdded];
    } else {
        return nil;
    }
}


-(DBConstraint*)createConstraintWithLhs:(MPWExpression*)lhs rhs:(MPWExpression*)rhs inContext:aContext
{
    NSArray *bindings = [self bindingsForLhs:lhs rhs:rhs inContext:aContext];
    NSArray *constraintVars=[self constraintVarsForBindings:bindings];

    DBConstraint *c= [self constraintWithVariables:constraintVars strength:0];
//    NSLog(@"constraint before adding block: %@",c);
    id convertedBlock = [self convertRHSToBlock:rhs inContext:aContext];
    int numParams =[[convertedBlock formalParameters] count];
    [c addBlock:convertedBlock withNumArgs:numParams];
//    NSLog(@"constraint after adding block: %@",c);
    [self addConstraint:c];
    return c;
}

-(void)addFormulaWithLHS:(MPWExpression*)lhs rhs:(MPWExpression*)rhs toConstraint:existingConstraint inContext:aContext
{
    [existingConstraint add1ArgBlock:[self convertRHSToBlock:rhs inContext:aContext ]];
}

-(DBConstraint*)constraintWithLhs:(MPWExpression*)lhs rhs:(MPWExpression*)rhs inContext:aContext
{
    DBConstraint *existingConstraint=[self lookupConstraintWithLhs:lhs rhs:rhs inContext:aContext];
    if ( existingConstraint) {
        [self addFormulaWithLHS:lhs rhs:rhs toConstraint:existingConstraint inContext:aContext];
    } else {
        existingConstraint=[self createConstraintWithLhs:lhs rhs:rhs inContext:aContext];
    }
    return existingConstraint;
}


-(DBConstraint*)constraintWithAssignmentExpression:(MPWAssignmentExpression*)expr inContext:aContext
{
    return [self constraintWithLhs:[expr lhs] rhs:[expr rhs] inContext:aContext];
}


-(DBConstraint*)constraintWithBidirectionalConstraintExpression:(MPWAssignmentExpression*)expr inContext:aContext
{
    DBConstraint *c = [self constraintWithLhs:[expr lhs] rhs:[expr rhs] inContext:aContext];
    id convertedBlock = [self convertRHSToBlock:[expr lhs] inContext:aContext];
    int numParams =[[convertedBlock formalParameters] count];
    [c addBlock:convertedBlock withNumArgs:numParams];
    return c;
}



-(DBConstraint*)constraintWithSTBlock:(MPWBlockContext*)block inContext:aContext
{
    MPWAssignmentExpression *e=[[block block] statements];
    return [self constraintWithAssignmentExpression:e inContext:aContext];
    
}

-(DBConstraint*)constraintWithSTBlock:(MPWBlockInvocable*)block
{
    return [self constraintWithSTBlock:block inContext:[block context]];
}



@end

@implementation MPWBlockContext(constraint)


-constraintIn:(DBSolver*)solver
{
    return [solver constraintWithSTBlock:self];
}

@end
