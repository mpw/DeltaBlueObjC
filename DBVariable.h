//
//  DBVariable.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import <Foundation/Foundation.h>

#import "List.h"
#import "Constraints.h"

@class DBConstraint,DBSolver;

@interface DBVariable : NSObject
{
    Variable variable;
    DBSolver *solver;
}

idAccessor_h(solver,setSolver)

+variableWithName:(NSString*)name intValue:(long)value;
-initWithName:(NSString*)name intValue:(long)value;
-initConstantWithName:(NSString*)name intValue:(long)value;
-(Variable)variable;
-(void)print;
-(DBConstraint*)multiplyBy:(DBVariable*)other into:(DBVariable*)result strength:(int)strength;
-(DBConstraint*)divideBy:(DBVariable*)other into:(DBVariable*)result strength:(int)strength;
-(DBConstraint*)add:(DBVariable*)other into:(DBVariable*)result strength:(int)strength;

-(long)intValue;
-(void)_setIntValue:(long)newValue;
-(void)assignInt:(long)newValue;

-(NSMutableArray*)constraints;

-(void)addConstraint:(DBConstraint*)newConstraint;
-(void)removeConstraint:(DBConstraint*)oldConstraint;
-(BOOL)isKnownWithMark:(long)mark;

longAccessor_h(mark , setMark )

@end
