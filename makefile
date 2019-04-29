# COMP = nvcc

# MTFILE = cu
# MT = mt-19937

# mtmake:
# 	$(COMP) -o $(MT) $(MT).$(MTFILE)

all:
	# nvcc mt-19937.cu -o mt-19937
	nvcc hybridtausworthe.cu -o hybridtauswortheParallel
	nvcc combinedtausworthe.cu -o combinedtauswortheParallel

	g++ combinedtausworthe.c -o combinedtauswortheSerial
	g++ hybridtausworthe.c -o hybridtauswortheSerial
