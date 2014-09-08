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
        if ( [var externalReference] == binding) {
            return var;
        }
    }
    return nil;
}


-(DBVariable*)constraintVarWithBinding:(MPWBinding*)aBinding
{
    DBVariable *var=[self lookupDBVariableWithBinding:aBinding];
    if (!var) {
        var=[self variableWithName:[aBinding name] intValue:0];
        [var setExternalReference:aBinding];
    }
    return var;
}


-(DBConstraint *)constraintWithRef:(MPWBinding *)ref1 andRef:(MPWBinding *)ref2
{
    DBVariable *v1 = [self constraintVarWithBinding:ref1];
    DBVariable *v2 = [self constraintVarWithBinding:ref2];
    return [v1 constraintWith:v2];
}

-(MPWBlockInvocable*)convertAssignment:(MPWAssignmentExpression*)a inContext:aContext
{
    MPWExpression *e=[a rhs];
    NSString* arg=[[[e variableNamesRead] allObjects] firstObject];
    MPWStatementList *newStatements = [MPWStatementList statementList];
    [newStatements addStatement:e];
    
    MPWBlockExpression *newBlock = [MPWBlockExpression blockWithStatements:newStatements arguments:@[ arg]];
    return [MPWBlockContext blockContextWithBlock:newBlock context:aContext];
}

-(DBConstraint*)constraintWithAssignmentExpression:(MPWAssignmentExpression*)expr inContext:aContext
{
    MPWBinding *written = [[[expr lhs] identifier] bindingWithContext:aContext];
                           
//    MPWBinding *written=[[[[[block block] variablesWritten] allObjects] firstObject] bindingWithContext:aContext];
    
    
    
    NSArray *read=[[[[[expr rhs] variablesRead] allObjects] collect] bindingWithContext:aContext];
    NSArray *bindings = [@[written] arrayByAddingObjectsFromArray:read];
    NSArray *variables = [[self collect] constraintVarWithBinding:[bindings each]];
    
    
    DBConstraint *c= [self constraintWithVariables:variables strength:0];
    [c add1ArgBlock:(OneArgBlock)[self convertAssignment:expr inContext:aContext]];
    [self addConstraint:c];
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
