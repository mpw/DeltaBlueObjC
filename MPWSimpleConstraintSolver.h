//
//  MPWSimpleConstraintSolver.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 06/06/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class STCompiler;

@interface MPWSimpleConstraintSolver : NSObject {
	NSMutableArray* formulae;
	NSMutableSet *changedVariables;
    STCompiler *compiler;
}

+solver;
-(void)markChanged:(NSSet*)newChanged;

@end
