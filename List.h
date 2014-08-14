/***************************************************************************
 List.h

    Supports variable sized, ordered lists of elements.

****************************************************************************/

#include <stdbool.h>

typedef	void (*Proc)();
typedef	void * Element;

typedef struct {
    Element	*slots;		/* variable-sized array of element slots */
    int		slotCount;	/* number of slots currently allocated */
    int		first;		/* index of first element */
    int		last;		/* index of last element (first-1, if empty) */
} *List, ListStruct;

/* Creation and Destruction */
  List		List_Create(int);
  void		List_Destroy(List);

/* Enumeration and Queries */
  void		List_Do(List, Proc);
  int		List_Size(List);

/* Adding */
  void		List_Add(List, Element);
  void		List_Append(List, List);

/* Removing */
  void		List_Remove(List, Element);
  void		List_RemoveAll(List);
  Element	List_RemoveFirst(List);
