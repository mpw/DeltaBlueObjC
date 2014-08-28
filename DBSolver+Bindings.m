//
//  DBSolver+Bindings.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/28/14.
//
//

#import "DBSolver+Bindings.h"
#import <ObjectiveSmalltalk/MPWBinding.h>

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

@end
