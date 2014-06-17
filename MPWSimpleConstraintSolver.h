//
//  MPWSimpleConstraintSolver.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 06/06/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/MPWStCompiler.h>

@interface MPWSimpleConstraintSolver : MPWStCompiler {
	NSMutableArray* formulae;
	NSMutableSet *changedVariables;
}

+solver;

@end
