#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/resource.h>
#include "List.h"
#include "Constraints.h"
#include "DeltaBlue.h"
#include "UsefulConstraints.h"

/***************************************************************************

    Private Prototypes

****************************************************************************/


static long Milliseconds(void);
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

static long Milliseconds()
{
/*
    struct timeval v;
    struct timezone z;

    gettimeofday(&v,&z);
*/
    struct rusage rusage;

    getrusage(RUSAGE_SELF, &rusage);
    return (rusage.ru_utime.tv_sec * 1000) + (rusage.ru_utime.tv_usec / 1000);
}

static void Start()
{
    startTime = Milliseconds();
}

static void Finish(milliseconds)
long *milliseconds;
{
    *milliseconds = Milliseconds() - startTime;
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

    printf("Case 1:\n");
  Start();
    editC = EditC(first, S_strongDefault);
  Finish(&msecs);
    printf("  Add Constraint: %ld msecs.\n", msecs);

  Start();
    plan = ExtractPlanFromConstraint(editC);
  Finish(&msecs);
    printf(
    	"  Make Plan: %ld msecs (plan is length %d).\n",
    	msecs, List_Size(plan));

  Start();
    for (i = 0; i < 100; i++) {
	ExecutePlan(plan);
    }
  Finish(&msecs);
    printf("  Execute Plan: %.3f msecs.\n", msecs / 100.0);
    List_Destroy(plan);

  Start();
    DestroyConstraint(editC);
  Finish(&msecs);
    printf("  Remove Constraint: %ld msecs\n", msecs);

    printf("Case 2:\n");
  Start();
    editC = EditC(last, S_strongDefault);
  Finish(&msecs);
    printf("  Add Constraint: %ld msecs.\n", msecs);

  Start();
    plan = ExtractPlanFromConstraint(editC);
  Finish(&msecs);
    printf(
	"  Make Plan: %ld msecs (plan is length %d).\n",
	msecs, List_Size(plan));

  Start();
    for (i = 0; i < 100; i++) {
	ExecutePlan(plan);
    }
  Finish(&msecs);
    printf("  Execute Plan: %.3f msecs.\n", msecs / 100.0);
    List_Destroy(plan);

  Start();
    DestroyConstraint(editC);
  Finish(&msecs);
    printf("  Remove Constraint: %ld msecs\n", msecs);

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

    Change(scale, 2);
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

#ifdef MACINTOSH
#include <console.h>
#endif

main(argc, argv)
int argc;
char **argv;
{
    int n;

#ifdef MACINTOSH
    argc = ccommand(&argv);
    printf("Macintosh Delta Blue Tests\n");
#else
    printf("DECStation Delta Blue Tests\n");
#endif
    if (argc < 2) {
	printf("usage: %s <count>\n", argv[0]);
	exit(-1);
    }
    sscanf(&*argv[1], "%d", &n);
    Benchmark(n);
    ProjectionTest(n);
    exit(0);
}
