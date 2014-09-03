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

-(DBVariable*)constraintVarWithBinding:(MPWBinding*)aBinding
{
    DBVariable *var=[self variableWithName:[aBinding name] intValue:0];
    [var setExternalReference:aBinding];
    return var;
}


-(DBConstraint *)constraintWithRef:(MPWBinding *)ref1 andRef:(MPWBinding *)ref2
{
    DBVariable *v1 = [self constraintVarWithBinding:ref1];
    DBVariable *v2 = [self constraintVarWithBinding:ref2];
    return [v1 constraintWith:v2];
}

-(MPWBlockInvocable*)convertBlock:(MPWBlockInvocable*)block
{
    MPWAssignmentExpression *a=[[block block] statements];
    MPWExpression *e=[a rhs];
    NSString* arg=[[[e variableNamesRead] allObjects] firstObject];
    MPWStatementList *newStatements = [MPWStatementList statementList];
    [newStatements addStatement:e];
    
    MPWBlockExpression *newBlock = [MPWBlockExpression blockWithStatements:newStatements arguments:@[ arg]];
    return [MPWBlockContext blockContextWithBlock:newBlock context:[block context]];
}


-(DBConstraint*)constraintWithSTBlock:(MPWBlockInvocable*)block inContext:aContext
{
    MPWBinding *written=[[[[[block block] variablesWritten] allObjects] firstObject] bindingWithContext:aContext];
    NSArray *read=[[[[[block block] variablesRead] allObjects] collect] bindingWithContext:aContext];
    NSArray *bindings = [read arrayByAddingObject:written];
    NSArray *variables = [[self collect] constraintVarWithBinding:[bindings each]];
    
    
    DBConstraint *c= [self constraintWithVariables:variables strength:0];
    [c add1ArgBlock:(OneArgBlock)[self convertBlock:block]];
    [self addConstraint:c];
    return c;
}



@end
