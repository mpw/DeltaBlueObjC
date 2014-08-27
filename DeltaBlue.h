/***************************************************************************
 DeltaBlue.h

    DeltaBlue, an incremental dataflow constraint solver.

****************************************************************************/

void	InitDeltaBlue(void);
void	AddVariable(Variable);
void	DestroyVariable(Variable);
void	AddConstraint(Constraint);
List	ExtractPlan(void);
List	ExtractPlanFromConstraint(Constraint);
List	ExtractPlanFromConstraints(List);
