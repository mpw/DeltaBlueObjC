/***************************************************************************
 DeltaBlue.h

    DeltaBlue, an incremental dataflow constraint solver.

****************************************************************************/

void	InitDeltaBlue(void);
void	AddVariable(Variable);
void	DestroyVariable(Variable);
List	ExtractPlan(void);
List	ExtractPlanFromConstraint(Constraint);
List	ExtractPlanFromConstraints(List);
