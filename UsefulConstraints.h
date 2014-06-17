/***************************************************************************
 UsefulConstraints.h

    Some useful constraints. Each function instantiates and installs
    a constraint on the argument variables.

****************************************************************************/
 
Constraint StayC(Variable v, int);				/* keep v constant */
Constraint EditC(Variable v, int);				/* change v */
Constraint EqualsC(Variable a, Variable b, int);		/* a = b */
Constraint AddC(Variable a, Variable b, Variable sum, int);	/* a + b = sum */
Constraint MultiplyC(Variable a, Variable b, Variable prod, int);	/* a * b = prod */
Constraint ScaleOffsetC(Variable src, Variable scale, Variable offset, Variable dest, int);
								/* (src * scale) + offset = dest*/

