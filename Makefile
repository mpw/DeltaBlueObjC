OBJECTS = Constraints.o DeltaBlue.o List.o UsefulConstraints.o
CFLAGS = -O3

DBBench : DBBench.o $(OBJECTS)
	cc -o DBBench DBBench.o $(OBJECTS)

clean:
	rm *.o DBBench TestDeltaBlue
