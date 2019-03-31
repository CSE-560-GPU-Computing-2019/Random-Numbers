#include "mt-19937.h"

static mt_struct MT[MT_RNG_COUNT];
static uint32_t state[MT_NN];

const int    PATH_N = 24000000;
const int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
const int    RAND_N = MT_RNG_COUNT * N_PER_RNG;
const unsigned int SEED = 777;


int iDivUp(int a, int b)
{
    return ((a % b) != 0) ? (a / b + 1) : (a / b);
}

int iDivDown(int a, int b)
{
    return a / b;
}

//Align a to nearest higher multiple of b
int iAlignUp(int a, int b)
{
    return ((a % b) != 0) ?  (a - a % b + b) : a;
}

//Align a to nearest lower multiple of b
int iAlignDown(int a, int b)
{
    return a - a % b;
}

/////////////////////////
void initMTRef(const char *fname)
{

    FILE *fd = fopen(fname, "rb");
    if(!fd){
        shrLog("initMTRef(): failed to open %s\n", fname);
        shrLog("FAILED\n");
        exit(0);
    }

    for (int i = 0; i < MT_RNG_COUNT; i++){
        //Inline structure size for compatibility,
        //since pointer types are 8-byte on 64-bit systems (unused *state variable)
        if( !fread(MT + i, 16 /* sizeof(mt_struct) */ * sizeof(int), 1, fd) ){
            shrLog("initMTRef(): failed to load %s\n", fname);
            shrLog("FAILED\n");
            exit(0);
        }
    }

    fclose(fd);
}


void RandomRef(float *h_Random, int NPerRng, unsigned int seed)
{
    int iRng, iOut;

    for(iRng = 0; iRng < MT_RNG_COUNT; iRng++){
        MT[iRng].state = state;
        sgenrand_mt(seed, &MT[iRng]);

        for(iOut = 0; iOut < NPerRng; iOut++)
           h_Random[iRng * NPerRng + iOut] = ((float)genrand_mt(&MT[iRng]) + 1.0f) / 4294967296.0f;
    }
}


static void BoxMuller(float& u1, float& u2)
{
    float   r = sqrtf(-2.0f * logf(u1));
    float phi = 2 * PI * u2;
    u1 = r * cosf(phi);
    u2 = r * sinf(phi);
}


void BoxMullerRef(float *h_Random, int NPerRng)
{
    int i;

    for(i = 0; i < MT_RNG_COUNT * NPerRng; i += 2)
        BoxMuller(h_Random[i + 0], h_Random[i + 1]);
}


//////////////////////////
void loadMTGPU(const char *fname)
{
    FILE *fd = fopen(fname, "rb");
    if(!fd){
        shrLog("initMTGPU(): failed to open %s\n", fname);
        shrLog("FAILED\n");
        exit(0);
    }
    if( !fread(h_MT, sizeof(h_MT), 1, fd) ){
        shrLog("initMTGPU(): failed to load %s\n", fname);
        shrLog("FAILED\n");
        exit(0);
    }
    fclose(fd);
}


void seedMTGPU(unsigned int seed){
    int i;
    //Need to be thread-safe
    mt_struct_stripped *MT = (mt_struct_stripped *)malloc(MT_RNG_COUNT * sizeof(mt_struct_stripped));

    for(i = 0; i < MT_RNG_COUNT; i++){
        MT[i]      = h_MT[i];
        MT[i].seed = seed;
    }
    CUDA_SAFE_CALL( cudaMemcpyToSymbol(ds_MT, MT, sizeof(h_MT)) );

    free(MT);
}


__global__ void gpuRand(float *d_Random, int nPerRng)
{
    const int tid = blockDim.x * blockIdx.x + threadIdx.x;

    int iState, iState1, iStateM, iOut;
    unsigned int mti, mti1, mtiM, x;
    unsigned int mt[MT_NN], matrix_a, mask_b, mask_c;

    //Load bit-vector Mersenne Twister parameters
    matrix_a = ds_MT[tid].matrix_a;
    mask_b = ds_MT[tid].mask_b;
    mask_c = ds_MT[tid].mask_c;

    //Initialize current state
    mt[0] = ds_MT[tid].seed;
    for (iState = 1; iState < MT_NN; iState++)
        mt[iState] = (1812433253U * (mt[iState - 1] ^ (mt[iState - 1] >> 30)) + iState) & MT_WMASK;

    iState = 0;
    mti1 = mt[0];
    for (iOut = 0; iOut < nPerRng; iOut++)
    {
        iState1 = iState + 1;
        iStateM = iState + MT_MM;
        if(iState1 >= MT_NN) iState1 -= MT_NN;
        if(iStateM >= MT_NN) iStateM -= MT_NN;
        mti  = mti1;
        mti1 = mt[iState1];
        mtiM = mt[iStateM];

        // MT recurrence
        x    = (mti & MT_UMASK) | (mti1 & MT_LMASK);
        x    =  mtiM ^ (x >> 1) ^ ((x & 1) ? matrix_a : 0);

        mt[iState] = x;
        iState = iState1;

        //Tempering transformation
        x ^= (x >> MT_SHIFT0);
        x ^= (x << MT_SHIFTB) & mask_b;
        x ^= (x << MT_SHIFTC) & mask_c;
        x ^= (x >> MT_SHIFT1);

        //Convert to (0, 1] float and write to global memory
        d_Random[tid + iOut * MT_RNG_COUNT] = ((float)x + 1.0f) / 4294967296.0f;
    }
}


__device__ inline void BoxMuller(float& u1, float& u2)
{
    float   r = sqrtf(-2.0f * logf(u1));
    float phi = 2 * PI * u2;
    u1 = r * __cosf(phi);
    u2 = r * __sinf(phi);
}


__global__ void BoxMullerGPU(float *d_Random, int nPerRng)
{
    const int      tid = blockDim.x * blockIdx.x + threadIdx.x;

    for (int iOut = 0; iOut < nPerRng; iOut += 2)
        BoxMuller(
                d_Random[tid + (iOut + 0) * MT_RNG_COUNT],
                d_Random[tid + (iOut + 1) * MT_RNG_COUNT]
                );
}


int main()
{
    FILE *log_file;
    log_file = fopen("mt-19937.txt", "w"); 

    float *d_rand_out, *h_randCPU_out, *h_randGPU_out;

    //Allocating memory
    h_randCPU_out  = (float *)malloc(RAND_N * sizeof(float));
    h_randGPU_out  = (float *)malloc(RAND_N * sizeof(float));
    cudaMalloc((void **)&d_rand_out, RAND_N * sizeof(float))


    fprintf(log_file, "Loading CPU and GPU twisters configurations...\n");
    initMTRef('data/MersenneTwister.raw');
    loadMTGPU('data/MersenneTwister.dat');
    seedMTGPU(SEED);

    cutCreateTimer(&hTimer)

    int numIterations = 100;
	for (int i = -1; i < numIterations; i++)
	{
		if (i == 0)
		{
			cudaThreadSynchronize();
			cutResetTimer(hTimer);
			cutStartTimer(hTimer);
		}
	RandomGPU<<<32, 128>>>(d_Rand, N_PER_RNG);
    #ifdef DO_BOXMULLER
    BoxMullerGPU<<<32, 128>>>(d_Rand, N_PER_RNG);
    #endif
    }

    cudaThreadSynchronize()

    fprintf(log_file, "MersenneTwister, Throughput = %.4f GNumbers/s, Time = %.5f s, Size = %u Numbers, NumDevsUsed = %u, Workgroup = %u\n", 1.0e-9 * RAND_N / gpuTime, gpuTime, RAND_N, 1, 128);
    cudaMemcpy(h_randGPU_out, d_rand_out, RAND_N * sizeof(float), cudaMemcpyDeviceToHost)

    //time this
    RandomRef(h_RandCPU, N_PER_RNG, SEED);
    #ifdef DO_BOXMULLER
    BoxMullerRef(h_RandCPU, N_PER_RNG);
    #endif

    return 0;
}