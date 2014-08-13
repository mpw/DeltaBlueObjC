#include <stdio.h>
#include "List.h"
#include "Constraints.h"
#include "DeltaBlue.h"
#include "UsefulConstraints.h"

/***************************************************************************

    Private Prototypes

****************************************************************************/

long MillisecondClock(void);
static void Start(void);
static void Finish(long*);
static void Assign(Variable, long);
static void Change(Variable, long);
static void Benchmark(int);
static void ProjectionTest(int);
static void TempertureConverter(void);
static void TreeTest(int);
static Variable MakeTree(int);

/***************************************************************************

    Timing Functions

****************************************************************************/

static long startTime;


#include <sys/time.h>
long MillisecondClock()
{
    struct timeval v;
    struct timezone z;

    gettimeofday(&v,&z);
    return (v.tv_sec * 1000) + (v.tv_usec / 1000);
}


static void Start()
{
    startTime = MillisecondClock();
}

static void Finish(milliseconds)
long *milliseconds;
{
    *milliseconds = MillisecondClock() - startTime;
}

/***************************************************************************
*
* This test builds and tests a Fahrenheit to Celcius temperature converter.
*
****************************************************************************/

void TempertureConverter()
{
    Variable celcius, fahrenheit, t1, t2, nine, five, thirtyTwo;
    Constraint addC, multC1, multC2;

    InitDeltaBlue();
    celcius = Variable_Create("C", 0);
    fahrenheit = Variable_Create("F", 0);
    t1 = Variable_Create("t1", 1);
    t2 = Variable_Create("t2", 1);
    nine = Variable_CreateConstant("*const*", 9);
    five = Variable_CreateConstant("*const*", 5);
    thirtyTwo = Variable_CreateConstant("*const*", 32);

    printf("Before adding constraints:\n  ");
    Variable_Print(celcius); printf(" = ");
    Variable_Print(fahrenheit); printf("\n\n");

    printf("After adding constraints:\n  ");
    multC1 = MultiplyC(celcius, nine, t1, S_required);
    multC2 = MultiplyC(t2, five, t1, S_required);
    addC = AddC(t2, thirtyTwo, fahrenheit, S_required);
    Constraint_Print(multC1); printf("  ");
    Constraint_Print(multC2); printf("  ");
    Constraint_Print(addC); printf("  ");
    Variable_Print(celcius); printf(" = ");
    Variable_Print(fahrenheit); printf("\n\n");

    printf("Changing celcius to 0:\n  ");
    Assign(celcius, 0);
    Variable_Print(celcius); printf(" = ");
    Variable_Print(fahrenheit); printf("\n\n");

    printf("Changing fahrenheit to 212:\n  ");
    Assign(fahrenheit, 212);
    Variable_Print(celcius); printf(" = ");
    Variable_Print(fahrenheit); printf("\n\n");

    printf("Changing celcius to -40:\n  ");
    Assign(celcius, -40);
    Variable_Print(celcius); printf(" = ");
    Variable_Print(fahrenheit); printf("\n\n");

    printf("Changing fahrenheit to 70:\n  ");
    Assign(fahrenheit, 70);
    Variable_Print(celcius); printf(" = ");
    Variable_Print(fahrenheit); printf("\n\n");
}

/* This is how to assign to constrained variables. */
static void Assign(v, newValue)
Variable v;
long newValue;
{
    Constraint	editC;
    long 	msecs;
    List	plan;

    editC = EditC(v, S_required);
    if (SATISFIED(editC)) {
	v->value = newValue;
	plan = ExtractPlanFromConstraint(editC);
	ExecutePlan(plan);
	List_Destroy(plan);
    }
    DestroyConstraint(editC);
}

/***************************************************************************
*
* This is the standard DeltaBlue benchmark. A long chain of equality
* constraints is constructed with a stay constraint on one end. An edit
* constraint is then added to the opposite end and the time is measured for
* adding and removing this constraint, and extracting and executing a
* constraint satisfaction plan. There are two cases. In case 1, the added
* constraint is stronger than the stay constraint and values must propagate
* down the entire length of the chain. In case 2, the added constraint is
* weaker than the stay constraint so it cannot be accomodated. The cost in
* this case is, of course, very low. Typical situations lie somewhere between
* these two extremes.
*
****************************************************************************/

static void Benchmark(n)
int n;
{
    long 	msecs, i;
    char	name[20];
    Variable	prev, v, first, last;
    Constraint	editC;
    List		plan;

    InitDeltaBlue();
    prev = first = last = NULL;

  Start();
    for (i = 0; i < n; i++) {
	sprintf(name, "v%ld", i);
	v = Variable_Create(name, 0);
	if (prev != NULL) {
	    EqualsC(prev, v, S_required);
	}
	if (i == 0) first = v;
	if (i == (n-1)) last = v;
	prev = v;
    }
  Finish(&msecs);
    printf("\n%ld msecs to add %d constraints.\n", msecs, n);
    StayC(last, S_default);

  Start();
    editC = EditC(first, S_strongDefault);
  Finish(&msecs);
    printf("Add Constraint (case 1): %ld msecs.\n", msecs);

  Start();
    plan = ExtractPlanFromConstraint(editC);
  Finish(&msecs);
    printf(
    	"Make Plan (case 1): %ld msecs (plan is length %d).\n",
    	msecs, List_Size(plan));

  Start();
    for (i = 0; i < 100; i++) {
	ExecutePlan(plan);
    }
  Finish(&msecs);
    printf("Execute Plan (case 1): %.3f msecs.\n", msecs / 100.0);
    List_Destroy(plan);

  Start();
    DestroyConstraint(editC);
  Finish(&msecs);
    printf("Remove Constraint (case 1): %ld msecs\n", msecs);

  Start();
    editC = EditC(first, S_weakDefault);
  Finish(&msecs);
    printf("Add Constraint (case 2): %ld msecs.\n", msecs);

  Start();
    plan = ExtractPlanFromConstraint(editC);
  Finish(&msecs);
    printf(
	"Make Plan (case 2): %ld msecs (plan is length %d).\n",
	msecs, List_Size(plan));

  Start();
    for (i = 0; i < 100; i++) {
	ExecutePlan(plan);
    }
  Finish(&msecs);
    printf("Execute Plan (case 2): %.3f msecs.\n", msecs / 100.0);
    List_Destroy(plan);

  Start();
    DestroyConstraint(editC);
  Finish(&msecs);
    printf("Remove Constraint (case 2): %ld msecs\n", msecs);

  Start();
    editC = EditC(last, S_strongDefault);
  Finish(&msecs);
    printf("Add Constraint (case 3): %ld msecs.\n", msecs);

  Start();
    plan = ExtractPlanFromConstraint(editC);
  Finish(&msecs);
    printf(
	"Make Plan (case 3): %ld msecs (plan is length %d).\n",
	msecs, List_Size(plan));

  Start();
    for (i = 0; i < 100; i++) {
	ExecutePlan(plan);
    }
  Finish(&msecs);
    printf("Execute Plan (case 3): %.3f msecs.\n", msecs / 100.0);
    List_Destroy(plan);

  Start();
    DestroyConstraint(editC);
  Finish(&msecs);
    printf("Remove Constraint (case 3): %ld msecs\n\n", msecs);

}

/***************************************************************************
*
* This test constructs a two sets of variables related to each other by a
* simple linear transformation (scale and offset). The time is measured to
* change a variable on either side of the mapping and to change the scale or
* offset factors. It has been tested for up to 2000 variable pairs.
*
****************************************************************************/

static void ProjectionTest(n)
int n;
{
    Variable	src, scale, offset, dest;
    long 	msecs, i;
    char	name[20];

    InitDeltaBlue();

  Start();
    scale = Variable_Create("scale", 10);
    offset = Variable_Create("offset", 1000);

    for (i = 1; i <= n; i++) {
	/* make src and dest variables */
	sprintf(name, "src%ld", i);
	src = Variable_Create(name, i);
	sprintf(name, "dest%ld", i);
	dest = Variable_Create(name, i);

	/* add stay on src */
	StayC(src, S_default);

	/* add scale/offset constraint */
	ScaleOffsetC(src, scale, offset, dest, S_required);
    }
  Finish(&msecs);
    printf("\nSetup time for %d points: %ld msecs.\n", n, msecs);

    Change(src, 17);
    Change(dest, 1050);
    Change(scale, 5);
    Change(offset, 2000);
}

static void Change(v, newValue)
Variable v;
long newValue;
{
    Constraint	editC;
    long 	i, msecs;
    List	plan;

    printf("Changing %s...\n", v->name);
  Start();
    editC = EditC(v, S_strongDefault);
  Finish(&msecs);
    printf("  Adding Constraint: %ld msecs.\n", msecs);

  Start();
    plan = ExtractPlanFromConstraint(editC);
  Finish(&msecs);
    printf("  Making Plan (length: %d): %ld msecs.\n", List_Size(plan), msecs);

  Start();
    v->value = newValue;
    for (i = 0; i < 100; i++) {
	ExecutePlan(plan);
    }
  Finish(&msecs);
    printf("  Executing Plan: %.3f msecs.\n", msecs / 100.0);
    List_Destroy(plan);

  Start();
    DestroyConstraint(editC);
  Finish(&msecs);
    printf("  Removing Constraint: %ld msecs\n", msecs);
}

/***************************************************************************
*
* This test constructs a full binary tree of add constraints of the given
* depth and then measures the time to change the root variable. Log(depth)
* constraints must be traversed. DeltaBlue chooses an arbitrary path to a
* leaf of the tree.
*
****************************************************************************/

extern List allVariables;

static void TreeTest(depth)
int depth;
{
    Variable root;
    long msecs;

    InitDeltaBlue();
    printf("Adder tree of depth %d\n", depth);

  Start();
    root = MakeTree(depth);
  Finish(&msecs);
    /* Note: with stays, there is one constraint per variable */
    printf(
	"%d constraints added in %ld msecs.\n",
	List_Size(allVariables), msecs);
    Change(root, 17);
    printf("\n");
}

/* returns the root variable of an adder tree of the given depth */
static Variable MakeTree(depth)
int depth;
{
    Variable root, left, right;

    if (depth <= 0) {
	root = Variable_Create("leaf", 1);
	StayC(root, S_default);
    } else {
	root = Variable_Create("nonleaf", 1);
	left = MakeTree(depth - 1);
	right = MakeTree(depth - 1);
	AddC(left, right, root, S_required);
    }
    return root;
}

main()
{
    char **junk;

#ifdef MACINTOSH
    ccommand(&junk);
    printf("Macintosh Delta Blue Tests\n");
#else
    printf("DECStation Delta Blue Tests\n");
#endif

    printf("Size of List is %d\n", sizeof(ListStruct));
    printf("Size of Variable is %d\n", sizeof(VariableStruct));
    printf("Size of Constraint is %d\n\n", sizeof(ConstraintStruct));

    TempertureConverter();
    TreeTest(10);
    Benchmark(50);
    Benchmark(100);
    Benchmark(200);
    Benchmark(400);
    Benchmark(800);
    ProjectionTest(250);
    ProjectionTest(500);
    ProjectionTest(1000);
    ProjectionTest(2000);
}
