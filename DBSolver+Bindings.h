//
//  DBSolver+Bindings.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/28/14.
//
//

#import "DBSolver.h"

@class MPWBinding;

@interface DBSolver (Bindings)

-(DBVariable*)constraintVarWithBinding:(MPWBinding*)aBinding;

-(DBConstraint*)constraintWithSTBlock:(MPWBlockInvocable*)block inContext:aContext;

@end
