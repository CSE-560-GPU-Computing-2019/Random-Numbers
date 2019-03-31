COMP = nvcc

MTFILE = cu
MT = mt-19937

mtmake:
	$(COMP) -o $(MT) $(MT).$(MTFILE)