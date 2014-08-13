//
//  MPWConstraintSet.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 04/06/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWConstraintSet : MPWObject {
	NSMutableArray *variables;
	NSMutableArray *todo1,*todo2,*hot;
}

-(void)addVariable:aVariable;

@end
