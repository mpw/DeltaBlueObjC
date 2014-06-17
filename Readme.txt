This directory contains the source code for an implementation of the
DeltaBlue incremental dataflow constraint solver written in portable C.

The files are:
  List.h,.c -- a simple ordered list abstract data type
  Constraints.h,.c -- basic constraint and variable definitions
  DeltaBlue.h,.c -- the DeltaBlue algorithm
  UsefulConstraints.h,.c -- functions to build some useful constraints
  TestDeltaBlue.c -- DeltaBlue benchmark program
  DBBench.c -- an alternative DeltaBlue benchmark program
  Readme.txt -- this file

The List abstract data type supports variable-sized, ordered collections
of objects. Lists are used to represent plans, sets of constraints, and
are used in various internal data structures.

Constraints are applied to Variable objects. New variables are created by
calling Variable_Create() or Variable_CreateConstant(). The latter is a
convenient way to generate read-only constants for use in equations such as
a Fahrenheit-Celsius converter. For debugging purposes, variables may be
given names up to 9 characters long. These names are used only when
printing the variable and need not be unique.

The value field of a Variable may be examined by the client program at
any time. In order to ensure that constraints are enforced, however, the
client program must add edit constraints to any variables it wishes to
change and must only proceed if this edit constraint can be satisfied.
There is an example of how to do this in TestDeltaBlue.c.

Each kind of constraint has a corresponding creation procedure in
UsefulConstraints.c. For example, an Add constraint is created and
bound to the variables x, y and z by writing:

	AddC(x, y, z, S_required)

This creates an instance of an Add constraint, binds it to the given
variables, and installs it with a strength of "required". It may be
destroyed later by calling DestroyConstraint().

The behavior of a constraint is defined by a case statement on the value
of "constraint->whichMethod". If the value of whichMethod is NO_METHOD,
the constraint execution procedure does nothing. Otherwise, one of the
arms of the case statement will be executed, causing one of the constrained
variables to be modified to enforce the constraint. The programer must
supply an "execute" procedure for each kind of constraint. The default
"execute" procedure simply does nothing. The programmer must also specify
the number of methods (arms of the case statement) and which variable is
changed by each method. There are several examples of how to define new
kinds of constraints in UsefulConstraints.c.

To enforce the constraints, a resatisfaction plan is obtained from
the constraint graph. There are several ways to do this. The plan can
be constructed starting from a set of edit or other input constraints.
Alternatively, DeltaBlue's internal list of variables can be used as
the starting point for constructing the plan. The latter is sometimes
more convenient but takes time proportional to the number of variables
in the system. Once a plan has been obtained, it may be executed repeatedly
to propagate changes through the constraint graph. This technique can be
used to provide continuous feedback in a user interface when, for example,
the user drags a graphic object with the mouse.

In this implementation, plans contain pointers to actual constraints
and each constraint keeps track of the method to execute. This means
that, in this implementation, a plan cannot be used once the constraint
graph has changed (because the method each constraint executes may have
changed as a side effect of constraint satisfaction). Thus, one cannot
cache plans for later re-use. This could be easily changed by recording
the value of "whichMethod" along with each constraint in the plan.

The performance of DeltaBlue is good enough to handle thousands of
constraints on a Mac II and tens of thousands of constraints on a
DECStation. The test program includes a number of benchmarks. Some C
libraries have poor implementations of "malloc" which can slow down the
algorithm considerably. 

The entire DeltaBlue algorithm as described in the DeltaBlue tech report
is implemented in "DeltaBlue.c". See the tech report for a description and
comments. For the most part, this implementation is a direct transcription
of the pseudocode in the tech report into C.

	John Maloney
	April 2, 1991

