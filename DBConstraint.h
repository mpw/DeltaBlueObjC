//
//  DBConstraint.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import <Foundation/Foundation.h>

#include "List.h"
#include "Constraints.h"

@class DBConstraint;

typedef void (^ConstraintBlock)(DBConstraint *);


@interface DBConstraint : NSObject
{
    Constraint constraint;
}

+(instancetype)constraintWithCConstraint:(Constraint)aCConstraint;
-(Constraint)constraint;
-(BOOL)isSatisfiedInput;
-(DBVariable*)outputVariable;
-(void)execute;
-(void)addMethodBlock:(ConstraintBlock)aBlock;
-(DBVariable *)variableAtIndex:(int)anIndex;
+(instancetype)constraintWithVariables:(NSArray*)newVars strength:(int)strength;


@end
