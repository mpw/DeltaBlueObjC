//
//  MPWDataflowConstraintExpression+SolverIntegration.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 6/1/15.
//
//

#import "MPWDataflowConstraintExpression+SolverIntegration.h"

@implementation MPWDataflowConstraintExpression (SolverIntegration)

-(NSObject<MPWEvaluable>*)evaluateIn:aContext
{
    NSLog(@"evalute |=, aContext=%@ solver=%@",aContext,[aContext solver]);
    return [[aContext solver] constraintWithAssignmentExpression:self inContext:aContext];

}

@end
