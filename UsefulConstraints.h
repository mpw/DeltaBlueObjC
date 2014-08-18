/***************************************************************************
 UsefulConstraints.h

    Some useful constraints. Each function instantiates and installs
    a constraint on the argument variables.

****************************************************************************/

@class DBSolver,DBVariable;

Constraint StayC(DBVariable *v, int strength, DBSolver *solver);	/* keep v constant */
Constraint EditC(DBVariable *v, int strength, DBSolver *solver);
Constraint EqualsC(DBVariable *a, DBVariable *b,int strength, DBSolver *solver);  // a == b
Constraint AddC(DBVariable *a, DBVariable *b, DBVariable *sum, int, DBSolver *solver);	// a + b = sum
Constraint MultiplyC(DBVariable *a, DBVariable * b, DBVariable * prod, int strength, DBSolver *solver);	// a * b = prod
Constraint DivideC(DBVariable * a, DBVariable * b, DBVariable * result, int strength, DBSolver *solver);  // result = a / b

Constraint ScaleOffsetC(DBVariable * src, DBVariable * scale, DBVariable * offset, DBVariable * dest, int strength, DBSolver *solver);
								/* (src * scale) + offset = dest*/

