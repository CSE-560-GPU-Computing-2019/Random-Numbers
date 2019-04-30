#include <stdio.h>

POOL_PASSES = 10
A = 1664525 
B = 1013904223ULL

void Transform(){
    // K, and M are binary powers.
    const unsigned K = 128  // Size of pool
    const unsigned M = K/D;  // Number of threads, and LCG modulus
    float block_0, block_1 , block_2 , block_3; 
    for(int pass = 0; pass < POOL_PASSES; pass++){
        // Read the pool in using a pseudorandom permutation.
        unsigned s = tid;
         // M is a binary power, don't need %.
        // s is being recomputed as an LCG.
        s = (s*A+B) & (M-1); block_0=pool[(s<<3)+0];
        s = (s*A+B) & (M-1); block_1=pool[(s<<3)+1];
        s = (s*A+B) & (M-1); block_2=pool[(s<<3)+2];
        s = (s*A+B) & (M-1); block_3=pool[(s<<3)+3];
        // All pool values must be read before any are written.
        __syncthreads();
        // Perform in-place 4x4 orthogonal transform on block.
        TransformBlock(block);
        // Output the blocks in linear order.
        s=tid;
        pool[s]=block_0; s+=NT;
        pool[s]=block_1; s+=NT;
        pool[s]=block_2; s+=NT;
        pool[s]=block_3; s+=NT;
    }
}

__device__ void TransformBlock(float *b){
  float t=(b[0]+b[1]+b[2]+b[3])/2;
  b[0]=b[0]-t;
  b[1]=b[1]-t;
  b[2]=t-b[2];
  b[3]=t-b[3];
}


__device__ void generateRandomNumbers_wallace(
    unsigned seed,  // Initialization seed
    float *chi2Corrections,  // Set of correction values
    float *globalPool,  // Input random number pool
    float *output  // Output random numbers
    ){
    unsigned tid=threadIdx.x;
    // Load global pool into shared memory.
    unsigned offset = POOL_SIZE * blockIdx.x;
    for( int i = 0; i < 4; i++) pool[tid+THREADS*i] = globalPool[offset+TOTAL_THREADS*i+tid];
    __syncthreads();
      const unsigned lcg_a=241;
      const unsigned lcg_c=59;
      const unsigned lcg_m=256;
      const unsigned mod_mask = lcg_m-1;
      seed=(seed+tid)&mod_mask ;
      // Loop generating outputs repeatedly
    for( int loop = 0; loop < OUTPUTS_PER_RUN; loop++ ){
        Transform();
        unsigned intermediate_address;
        i_a = loop * 8 * TOTAL_THREADS) + 8 * THREADS * blockIdx.x + threadIdx.x;
        float chi2CorrAndScale=chi2Corrections[
          blockIdx.x * OUTPUTS_PER_RUN + loop];
        for( i = 0; i < 4; i++ )
          output[i_a + i*THREADS]=chi2CorrAndScale*pool[tid+THREADS*i];
    }
  }
  