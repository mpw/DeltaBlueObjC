//
//  MPWConstraintVariable.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 04/06/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWConstraintVariable.h"


@implementation MPWConstraintVariable


-(void)dealloc
{
	[super dealloc];
}

@end

@implementation MPWConstraintVariable(testing)

+(void)testSetAndGetVariable
{
	id var = [[[self alloc] init] autorelease];
	[var bindValue:@"42"];
	INTEXPECT( [[var value] intValue], 42 , @"set value");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testSetAndGetVariable",
		nil];
}

@end
