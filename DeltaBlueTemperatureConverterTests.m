//
//  DeltaBlueTemperatureConverterTests.m
//  DeltaBlue
//
//  Created by Marcel Weiher on 4/20/17.
//
//

#import "DeltaBlueTemperatureConverterTests.h"
#import "DBSolver.h"
#import <ObjectiveSmalltalk/MPWStCompiler.h>

@implementation DeltaBlueTemperatureConverterTests


-(MPWStCompiler*)compilerWithSolver
{
    DBSolver *solver=[DBSolver solver];
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler setSolver:solver];
    [compiler bindValue:self toVariableNamed:@"tester"];
    [compiler evaluateScriptString:@"scheme:ivar := ref:var:tester asScheme."];
    return compiler;
}




-(instancetype)init
{
    self=[super init];
    self.compiler = [self compilerWithSolver];
    [self setC:0];
    [self setF:32];
    [self setK:273];

    return self;
}

-(void)addC2FConstraint
{
    [self.compiler evaluateScriptString:@"ivar:f |= (9.0/5.0) * ivar:c + 32."];
}

-(void)addF2CConstraint
{
    [self.compiler evaluateScriptString:@"ivar:c |= (ivar:f - 32) * (5.0/9.0)."];
}

-(void)addK2CConstraint
{
    [self.compiler evaluateScriptString:@"ivar:c |= ivar:k - 273."];
}

-(void)addC2KConstraint
{
    [self.compiler evaluateScriptString:@"ivar:k |= ivar:c + 273."];
}


-(void)dealloc
{
    [super dealloc];
}

-(void)testJustCF
{
    INTEXPECT(self.f, 32, @"F initialized");
    [self addC2FConstraint];
    [self setC:100];
    INTEXPECT(self.f, 212, @"F at C 100");
    [self setC:100];
    [self setC:-40];
    INTEXPECT(self.f, -40, @"F at C -40");
    [self setF:100];
    INTEXPECT(self.c, -40, @"C doesn't change");
}

-(void)testJustFC
{
    INTEXPECT(self.c, 0, @"C initialized");
    [self addF2CConstraint];
    [self setF:212];
    INTEXPECT(self.c, 100, @"C at F 212");
    [self setF:-40];
    INTEXPECT(self.c, -40, @"C at F -40");
    [self setC:100];
    INTEXPECT(self.f, -40, @"F doesn't change");
}

-(void)testC2FBidirectional
{
    [self addC2FConstraint];                    // this order works
    [self addF2CConstraint];
    [self setC:100];
    INTEXPECT(self.f, 212, @"F at C 100");

    [self setF:-40];
    INTEXPECT(self.c, -40, @"C at F -40");

}

-(void)testF2CBidirectional
{
    [self addF2CConstraint];
    [self addC2FConstraint];                    // this order does not work
    [self setC:100];
    INTEXPECT(self.f, 212, @"F at C 100");
    
    [self setF:-40];
    INTEXPECT(self.c, -40, @"C at F -40");
    
}


+testFixture
{
    return [[self new] autorelease];
}

+(NSArray *)testSelectors
{
    return @[
             @"testJustCF",
             @"testJustFC",
             @"testC2FBidirectional",
             @"testF2CBidirectional",
             ];
}

@end