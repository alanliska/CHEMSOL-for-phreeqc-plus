FC = gfortran
FCFLAGS = -g
objects = BLOCKDATA1.o chemsol.o dg_ld.o readopt.o sci_lgvn.o solvout.o

main: $(objects)
	$(FC) $(FCFLAGS) -fdump-core -o main main.f90 $(objects)

%.o: %.f90
	$(FC) $(FCFLAGS) -c $<

%.o: %.f
	$(FC) $(FCFLAGS) -c $<

.PHONY: clean test diff

clean: 
	rm -f *.o *.mod *.MOD 

test: 
	time ./main vdw.par test1.cs >& test1_main.out & 

diff: 	
	diff --side-by-side --suppress-common-lines test1.log test1_main.out 
