#include "mt-19937.h"
#include <stdio.h>
#include <stdint.h>
<<<<<<< HEAD
// #include <shrUtils.h>
=======
>>>>>>> bca7277f2af986aa2b908854358b226236f595a9

#define DCMT_SEED 4172
#define MT_RNG_PERIOD 607
#define MT_RNG_COUNT 4096
#define MT_MM 9
#define MT_NN 19
#define MT_WMASK 0xFFFFFFFFU
#define MT_UMASK 0xFFFFFFFEU
#define MT_LMASK 0x1U
#define MT_SHIFT0 12
#define MT_SHIFTB 7
#define MT_SHIFTC 15
#define MT_SHIFT1 18
#define PI 3.14159265358979f

#define SHIFT1 18


typedef struct {
    uint32_t aaa;
    int mm,nn,rr,ww;
    uint32_t wmask,umask,lmask;
    int shift0, shift1, shiftB, shiftC;
    uint32_t maskB, maskC;
    int i;
    uint32_t *state;
}mt_struct;


typedef struct{
    unsigned int matrix_a;
    unsigned int mask_b;
    unsigned int mask_c;
    unsigned int seed;
} mt_struct_stripped;

static mt_struct MT[MT_RNG_COUNT];
static uint32_t state[MT_NN];



void sgenrand_mt(uint32_t seed, mt_struct *mts){
    int i;

    mts->state[0] = seed & mts->wmask;

    for(i = 1; i < mts->nn; i++){
        mts->state[i] = (UINT32_C(1812433253) * (mts->state[i - 1] ^ (mts->state[i - 1] >> 30)) + i) & mts->wmask;
        /* See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier. */
        /* In the previous versions, MSBs of the seed affect   */
        /* only MSBs of the array mt[].                        */
    }
    mts->i = mts->nn;
}


uint32_t genrand_mt(mt_struct *mts){
    uint32_t *st, uuu, lll, aa, x;
    int k,n,m,lim;

    if(mts->i >= mts->nn ){
        n = mts->nn; m = mts->mm;
        aa = mts->aaa;
        st = mts->state;
        uuu = mts->umask; lll = mts->lmask;

        lim = n - m;
        for(k = 0; k < lim; k++){
            x = (st[k]&uuu)|(st[k+1]&lll);
            st[k] = st[k + m] ^ (x >> 1) ^ (x&1U ? aa : 0U);
        }

        lim = n - 1;
        for(; k < lim; k++){
            x = (st[k] & uuu)|(st[k + 1] & lll);
            st[k] = st[k + m - n] ^ (x >> 1) ^ (x & 1U ? aa : 0U);
        }

        x = (st[n - 1] & uuu)|(st[0] & lll);
        st[n - 1] = st[m - 1] ^ (x >> 1) ^ (x&1U ? aa : 0U);
        mts->i=0;
    }

    x = mts->state[mts->i];
    mts->i += 1;
    x ^= x >> mts->shift0;
    x ^= (x << mts->shiftB) & mts->maskB;
    x ^= (x << mts->shiftC) & mts->maskC;
    x ^= x >> mts->shift1;

    return x;
}



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


const int    PATH_N = 24000000;
const int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
const int    RAND_N = MT_RNG_COUNT * N_PER_RNG;
const unsigned int SEED = 777;

__device__ static mt_struct_stripped ds_MT[MT_RNG_COUNT];
static mt_struct_stripped h_MT[MT_RNG_COUNT];

/////////////////////////
void initMTRef(const char *fname)
{

    FILE *fd = fopen(fname, "rb");
    if(!fd)
    {
        exit(0);
    }

    for (int i = 0; i < MT_RNG_COUNT; i++){
        //Inline structure size for compatibility,
        //since pointer types are 8-byte on 64-bit systems (unused *state variable)
        if( !fread(MT + i, 16 /* sizeof(mt_struct) */ * sizeof(int), 1, fd) )
        {
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


//////////////////////////
void loadMTGPU(const char *fname)
{
    FILE *fd = fopen(fname, "rb");
    if(!fd)
    {
        exit(0);
    }
    if( !fread(h_MT, sizeof(h_MT), 1, fd) )
    {
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
    cudaMemcpyToSymbol(ds_MT, MT, sizeof(h_MT));

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


int main()
{
    FILE *log_file;
    log_file = fopen("mt-19937.txt", "w"); 

    float *d_rand_out, *h_randCPU_out, *h_randGPU_out;

    //Allocating memory
    h_randCPU_out  = (float *)malloc(RAND_N * sizeof(float));
    h_randGPU_out  = (float *)malloc(RAND_N * sizeof(float));
    cudaMalloc((void **)&d_rand_out, RAND_N * sizeof(float));

    initMTRef("data/MersenneTwister.raw");
    loadMTGPU("data/MersenneTwister.dat");
    seedMTGPU(SEED);

    float hTimer;
    cudaEvent_t start, stop;
    cudaEventCreate (&start);
	cudaEventCreate (&stop);

    int numIterations = 100;
	for (int i = -1; i < numIterations; i++)
	{
		if (i == 0)
		{
			cudaThreadSynchronize();
			cudaEventRecord(start, 0);
		}
	gpuRand<<<32, 128>>>(d_rand_out, N_PER_RNG);
    }

    cudaEventRecord (stop, 0);
	cudaEventSynchronize (stop);
	cudaEventElapsedTime (&hTimer, start, stop);
    float gpuTime = 1.0e-3 * hTimer/(double)numIterations;

    fprintf(log_file, "MersenneTwister (GPU), Time = %f s, TP = %f GNumbers/s, Size = %u\n", gpuTime, 1.0e-9 * RAND_N / gpuTime, RAND_N);
    cudaMemcpy(h_randGPU_out, d_rand_out, RAND_N * sizeof(float), cudaMemcpyDeviceToHost);

    float hTimer_cpu;
    cudaEventRecord(start, 0);
    RandomRef(h_randCPU_out, N_PER_RNG, SEED);
    cudaEventRecord (stop, 0);
    cudaEventElapsedTime (&hTimer_cpu, start, stop);
    float cpuTime = 1.0e-3 * hTimer_cpu/(double)numIterations;

    fprintf(log_file, "MersenneTwister (CPU), Time = %f s, TP = %f GNumbers/s, Size = %u\n", cpuTime, 1.0e-9 * RAND_N / cpuTime, RAND_N);

    cudaFree(d_rand_out);
    return 0;
}