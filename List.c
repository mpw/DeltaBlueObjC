/***************************************************************************
 List.c

    Implementation of List.h.
    Invariants and relationships:
	slots != NULL
	slotCount > 0
	sizeof(*slots) == slotCount * sizeof(Element)
	0 <= first < slotCount
	-1 <= last < slotCount
	last >= first (if not empty)
	last == first - 1 (if empty)
	NumberOfItems == (last - first) + 1

****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include "List.h"

/* Private Prototypes */
static void Error(char*);
static void Grow(List);
static void MakeRoom(List);

/****** Create and Destruction ******/

List List_Create(initialCount)
int initialCount;
{
    register List newList;

    newList = (List) malloc(sizeof(ListStruct));
    if (newList == NULL) Error("out of memory");
    newList->slots = (Element *) malloc(initialCount * sizeof(Element));
    if (newList->slots == NULL) Error("out of memory");
    newList->slotCount = initialCount;
    newList->first = 0;
    newList->last = -1;
    return newList;
}

void List_Destroy(list)
register List list;
{
    if (list->slots == NULL) Error("bad ListStruct; already freed?");
    free(list->slots);
    list->slots = NULL;
    list->slotCount = 0;
    list->first = 0;
    list->last = -1;
    free(list);
}

/****** Enumeration and Queries ******/

void List_Do(list, proc)
List list;
register Proc proc;
{
    register Element *nextPtr = &(list->slots[list->first]);
    register Element *lastPtr = &(list->slots[list->last]);

    while (nextPtr <= lastPtr) {
	(*proc)(*nextPtr++);
    }
}

int List_Size(list)
register List list;
{
    return (list->last - list->first) + 1;
}

/****** Adding ******/

void List_Add(list, element)
register List list;
Element element;
{
    if (list->last >= (list->slotCount - 1)) MakeRoom(list);
    list->slots[++list->last] = element;
}

void List_Append(list1, list2)
register List list1;
List list2;
{
    register Element *nextPtr = &(list2->slots[list2->first]);
    register Element *lastPtr = &(list2->slots[list2->last]);

    while (nextPtr <= lastPtr) {
	List_Add(list1, *nextPtr++);
    }
}

/****** Removing ******/

void List_Remove(list, element)
List list;
Element element;
{
    register Element *srcPtr = &list->slots[list->first];
    register Element *destPtr = &list->slots[0];
    register Element *lastPtr = &list->slots[list->last];
    
    list->last = list->last - list->first;
    list->first = 0;
    while (srcPtr <= lastPtr) {
	if (*srcPtr == element) {
	    list->last--;
	} else {
	    *destPtr++ = *srcPtr;
	}
	srcPtr++;
    }
}

Element List_RemoveFirst(list)
register List list;
{
    register Element element;

    if (list->last < list->first) return NULL;
    element = list->slots[list->first++];
    return element;
}

void List_RemoveAll(list)
register List list;
{
    list->first = 0;
    list->last = -1;
}

/****** Private ******/

#define max(x, y) ((x) > (y) ? (x) : (y))
#define min(x, y) ((x) < (y) ? (x) : (y))

static void Error(errorString)
char* errorString;
{
    printf("List.c error: %s.\n", errorString);
    exit(-1);
}

static void Grow(list)
register List list;
{
    list->slotCount += min(max(list->slotCount, 2), 512);
    list->slots = (Element *) realloc(list->slots, (list->slotCount * sizeof(Element)));
    if (list->slots == NULL) Error("out of memory");
}

static void MakeRoom(list)
List list;
{
    register Element *srcPtr = &list->slots[list->first];
    register Element *destPtr = &list->slots[0];
    register Element *lastPtr = &list->slots[list->last];

    if (((list->last - list->first) + 1) >= list->slotCount) Grow(list);
    if (list->first == 0) return;
    while (srcPtr <= lastPtr) {
	*destPtr++ = *srcPtr++;
    }
    list->last = list->last - list->first;
    list->first = 0;
}
