//
//  DBSolver.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import <Foundation/Foundation.h>

#import "List.h"
#import "Constraints.h"

@class DBVariable,DBConstraint;

@interface DBSolver : NSObject
{
    long currentMark;
    List unsatisfied;	/* used to collect unsatisfied downstream constraints */
    int strength;		/* used to add unsatisfied constraints in strength order */

    NSMutableArray *allVariables;
    NSMutableArray *hot;	/* used to collect "hot" constraints */
    NSMutableArray *todo1; /* used by AddPropagate */
    NSMutableArray *todo2; /* used by RemovePropagate */
}

+(instancetype)solver;
-(void)addVariable:(DBVariable*)v;
-(void)addConstraint:(Constraint)c;
-(NSArray*)extractPlanFromConstraint:(DBConstraint*)c;
-(DBVariable*)variableWithName:(NSString*)name intValue:(long)value;
-(DBVariable*)constantWithName:(NSString*)name intValue:(long)value;

void AddConstraint( Constraint c);
void DestroyConstraint( Constraint c);

@end
