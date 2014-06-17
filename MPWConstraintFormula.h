//
//  MPWConstraintFormula.h
//  DeltaBlue
//
//  Created by Marcel Weiher on 06/06/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWConstraintFormula : MPWObject {
	id	source,compiled;
//	id	value;
//	BOOL	evaluated;
}

+formulaWithSource:aFormula compiled:aCompiledScript;
-(int)isInterestedInVariables:(NSSet*)variables;

@end
