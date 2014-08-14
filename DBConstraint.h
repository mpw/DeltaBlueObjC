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

@interface DBConstraint : NSObject
{
    Constraint constraint;
}

+(instancetype)constraintWithCConstraint:(Constraint)aCConstraint;

@end
