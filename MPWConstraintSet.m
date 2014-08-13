//
//  MPWConstraintSet.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 04/06/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWConstraintSet.h"
#import "MPWConstraintVariable.h"
#import <MPWFoundation/AccessorMacros.h>

@implementation MPWConstraintSet

objectAccessor( NSMutableArray , todo1, setTodo1 )
objectAccessor( NSMutableArray , todo2, setTodo2 )
objectAccessor( NSMutableArray , hot, setHot )
objectAccessor( NSMutableArray , variables, setVariables )

-init
{
	self = [super init];
	[self setVariables:[NSMutableArray array]];
	[self setTodo1:[NSMutableArray array]];
	[self setTodo2:[NSMutableArray array]];
	[self setHot:[NSMutableArray array]];
	return self;
}


-(void)addVariable:newVariable
{
	[variables addObject:newVariable];
}

-(void)dealloc
{
	[hot release];
	[todo1 release];
	[todo2 release];
	[variables release];
	[super dealloc];
}


@end
