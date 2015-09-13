//
//  DBSolver.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import <MPWFoundation/MPWFoundation.h>

#import "Constraints.h"

@class DBVariable,DBConstraint,MPWBlockInvocable;

@interface DBSolver : NSObject
{
    long currentMark;
    int strength;		/* used to add unsatisfied constraints in strength order */

    NSMutableArray *unsatisfied;	/* used to collect unsatisfied downstream constraints */
    NSMutableArray *allVariables;
    NSMutableArray *hot;	/* used to collect "hot" constraints */
    NSMutableArray *todo1; /* used by AddPropagate */
    NSMutableArray *todo2; /* used by RemovePropagate */
    NSMutableOrderedSet *allConstraints;
    
    NSMutableSet   *bindings;
    DBConstraint   *lastAdded;
    
    BOOL solving;
}

+(instancetype)solver;
-(void)addVariable:(DBVariable*)v;
-(NSArray*)extractPlanFromConstraint:(DBConstraint*)c;
-(DBVariable*)variableWithName:(NSString*)name intValue:(long)value;
-(DBVariable*)constantWithName:(NSString*)name intValue:(long)value;
-(void)addConstraint:(DBConstraint*)c;

-(DBConstraint*)constraintWithVariables:(NSArray*)vars strength:(int)newStrength;

boolAccessor_h(solving, setSolving)

objectAccessor_h(DBConstraint, lastAdded, setLastAdded)


@end
