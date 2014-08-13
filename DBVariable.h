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

@class DBConstraint;

@interface DBVariable : NSObject
{
    Variable variable;
}


+variableWithName:(NSString*)name value:(long)value;
-initWithName:(NSString*)name value:(long)value;
-initConstantWithName:(NSString*)name value:(long)value;
-(Variable)variable;
-(void)print;
-(DBConstraint*)multiplyBy:(DBVariable*)other into:(DBVariable*)result strength:(int)strength;

-(DBConstraint*)add:(DBVariable*)other into:(DBVariable*)result strength:(int)strength;

-(long)value;
-(void)assign:(long)newValue;

@end
