//
//  DBConstraint.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 8/13/14.
//
//

#import "DBConstraint.h"
#import "DBVariable.h"

#define SATISFIED(c)	((c)->whichMethod != NO_METHOD)

@implementation DBConstraint


+(instancetype)constraintWithCConstraint:(Constraint)aCConstraint;
{
    return [[[self alloc] initWithCConstraint:aCConstraint] autorelease];
}


+(instancetype)constraintWithVariables:(NSArray*)newVars strength:(int)strength
{
    return [[[self alloc] initWithVariables:newVars strength:strength] autorelease];
}

-initWithCConstraint:(Constraint)aCConstraint
{
    if ( self=[super init] ) {
        constraint=aCConstraint;
        // can't initialize methodBlocks here because we still
        // create temporary DBConstraint objects refering to
        // an underlying constraint struct
    }
    return self;
}

-initWithVariables:(NSArray*)vars strength:(int)strength
{
    int numVars = [vars count];
    Constraint c=Constraint_Create( numVars, strength);
    if ( c ) {
        self=[self initWithCConstraint:c];
        for (int i=0;i<numVars;i++ ) {
            c->variables[i]=[vars objectAtIndex:i];
            c->methodOuts[i]=i;
        }
    }
    
    return self;
}


-(Constraint)constraint
{
    return constraint;
}

-(NSUInteger)hash
{
    return (NSUInteger)constraint;
}

-(BOOL)isEqual:(id)object
{
    return constraint == [object constraint];
}

-(BOOL)isSatisfiedInput
{
    return (constraint->inputFlag && SATISFIED(constraint));
}

-(BOOL)isSatisfied
{
    return constraint->whichMethod != NO_METHOD;
}

-(DBVariable*)outputVariable
{
    return (constraint->variables[constraint->methodOuts[constraint->whichMethod]]);
}

-(NSMutableArray*)methodBlocks
{
    return constraint->methodBlocks;
}

-(void)addMethodBlock:(ConstraintBlock)aBlock
{
    [[self methodBlocks] addObject:[aBlock copy]];
    constraint->methodCount = [[self methodBlocks] count];
}

-(DBVariable *)variableAtIndex:(int)anIndex
{
    return constraint->variables[anIndex];
}

typedef id (^EightArgBlock)(id ,id ,id,id,id ,id ,id,id  );

typedef struct {
    int args[8];
} BlockArgList;

-(void)addBlock:aBlock withNumArgs:(int)numArgs
{
    EightArgBlock block=(EightArgBlock)aBlock;
    if ( constraint->varCount == numArgs+1 ) {
        int currentResultIndex = [[self methodBlocks] count];
        BlockArgList args;
        for (int i=0,target =0;i<3;i++,target++) {
            if ( i==currentResultIndex) {
                target++;
            }
            args.args[i]=target;
        }
        
        [self addMethodBlock:^(DBConstraint *c) {
            id values[8]={nil,nil,nil,nil,nil,nil,nil,nil };
            for (int i =0;i<numArgs;i++) {
                values[i]=[[c variableAtIndex:args.args[i]] value];
            }
            id result =block( values[0], values[1],values[2], values[3],values[4], values[5],values[6], values[7]);
            [[c variableAtIndex:currentResultIndex] _setValue:result];
        }];
        constraint->whichMethod=0;
    } else {
        NSLog(@"block with %d args only makes sense with constraint with %d vars, but constraint has %d",numArgs,numArgs+1,constraint->varCount);
    }
}

-(void)add2ArgBlock:(TwoArgBlock)aBlock
{
    [self addBlock:(id)aBlock withNumArgs:2];
}

-(void)add1ArgBlock:(TwoArgBlock)aBlock
{
    [self addBlock:(id)aBlock withNumArgs:1];
}


-(void)add2ArgBlock_old:(TwoArgBlock)aBlock
{
    if ( constraint->varCount == 3 ) {
        int currentResultIndex = [[self methodBlocks] count];
        DBVariable *resultVar=[self variableAtIndex:currentResultIndex];
        int args[3];
        for (int i=0,target =0;i<3;i++,target++) {
            if ( i==currentResultIndex) {
                target++;
            }
            args[i]=target;
        }
        int first=args[0];
        int second=args[1];

        [self addMethodBlock:^(DBConstraint *c) {
            id value1=[[c variableAtIndex:first] value];
            id value2=[[c variableAtIndex:second] value];
            id result =aBlock( value1, value2);
            [[c variableAtIndex:currentResultIndex] _setValue:result];
        }];
        constraint->whichMethod=0;
    } else {
        NSLog(@"2arg block only makes sense with 3 vars");
    }
}

-(void)add1ArgBlock_old:(OneArgBlock)aBlock
{
    if ( constraint->varCount == 2 ) {
        int currentResultIndex = [[self methodBlocks] count];
        int args[2];
        for (int i=0,target =0;i<2;i++,target++) {
            if ( i==currentResultIndex) {
                target++;
            }
            args[i]=target;
        }
        int first=args[0];
        [self addMethodBlock:^(DBConstraint *c) {
            id value1=[[c variableAtIndex:first] value];
            id result =aBlock( value1);
            [[c variableAtIndex:currentResultIndex] _setValue:result];
        }];
    } else {
        NSLog(@"1arg block only makes sense with 2 vars");
    }
}

-(void)execute
{
    int whichMethod = constraint->whichMethod;
    if ( whichMethod < [[self methodBlocks] count]) {
        ConstraintBlock block = [[self methodBlocks] objectAtIndex:whichMethod];
        if ( block ) {
            block( self );
        }
    } else {
        if ( constraint->execute) {
            constraint->execute( constraint);
        }
    }
}

-(int)numVars
{
    return constraint->varCount;
}

-(NSString *)description
{
    NSMutableString *description=[NSMutableString stringWithFormat:@"<%@:%p: %d vars: ",[self class],self,constraint->varCount];
    for (int i=0;i<constraint->varCount;i++) {
        [description appendFormat:@"%@ ",constraint->variables[i]];
    }
    [description appendFormat:@"%d methods whichMethod: %d outs: ",constraint->methodCount,constraint->whichMethod];
    for (int i=0;i<constraint->methodCount;i++) {
        [description appendFormat:@"%d ",constraint->methodOuts[i]];
    }
    [description appendString:@">"];
    return description;
}

-(void)destroy
{
    for (int i = constraint->varCount - 1; i >= 0; i--) {
        [constraint->variables[i] removeConstraint:self];
    }

    constraint->execute = NULL;
    // release as well?
}

-(void)clearMethod
{
    constraint->whichMethod = NO_METHOD;

}


-(BOOL)inputsKnownWithMark:(long)currentMark
{
    int	outIndex, i;
    
    outIndex = constraint->methodOuts[constraint->whichMethod];
    for (i = constraint->varCount - 1; i >= 0; i--) {
        if (i != outIndex) {
            if ( ![constraint->variables[i] isKnownWithMark:currentMark]) {
                return NO;
            }
        }
    }
    return YES;
}

-(BOOL)isConstantOutput
{
    int outIndex, i;
    
    if (constraint->inputFlag) return false;
    outIndex = constraint->methodOuts[constraint->whichMethod];
    for (i = constraint->varCount - 1; i >= 0; i--) {
        if (i != outIndex) {
            if (![constraint->variables[i] variable]->stay) return NO;
        }
    }
    return YES;
}


@end
