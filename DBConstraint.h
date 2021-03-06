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
typedef id (^OneArgBlock)(id a);
typedef id (^TwoArgBlock)(id a,id b);


@interface DBConstraint : NSObject
{
    Constraint constraint;
    NSMutableArray *realBlocks;
}

+(instancetype)constraintWithCConstraint:(Constraint)aCConstraint;
-(BOOL)isSatisfiedInput;
-(DBVariable*)outputVariable;
-(void)execute;
-(void)addMethodBlock:(ConstraintBlock)aBlock;
-(void)addBlock:aBlock withNumArgs:(int)numArgs;
//-(void)add2ArgBlock:(TwoArgBlock)aBlock;
//-(void)add1ArgBlock:(OneArgBlock)aBlock;

-(DBVariable *)variableAtIndex:(int)anIndex;
+(instancetype)constraintWithVariables:(NSArray*)newVars strength:(int)strength;
-(int)numVars;
-(BOOL)isSatisfied;
-(void)clearMethod;
-(BOOL)inputsKnownWithMark:(long)currentMark;
-(BOOL)isConstantOutput;
-(int)outputWalkStrength;

-(void)prepareForAdd;
-(void)destroy;
-(void)chooseMethodWithMark:(long)currentMark;
-(int)strength;
-(void)recalculate;
-(void)markInputs:(long)currentMark;

-(BOOL)hasVariables:(NSSet*)constraintVariables;
-(BOOL)hasSameVariablesAs:(DBConstraint*)otherConstraint;

@end
