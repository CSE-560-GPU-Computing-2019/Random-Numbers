#include <stdio.h>

typedef unsigned long long llu;

int iAlignUp(int a, int b){
    return ((a % b) != 0) ?  (a - a % b + b) : a;
}

int iDivUp(int a, int b){
    return ((a % b) != 0) ? (a / b + 1) : (a / b);
}

#define MT_RNG_COUNT 4096

const int    PATH_N = 24000000;
const int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
const int    RAND_N = MT_RNG_COUNT * N_PER_RNG;

__global__ void RandomCT(llu *device_array, int npr) {
    const int tid = blockDim.x * blockIdx.x + threadIdx.x;
    
    llu seed = 10 * tid + 5;

    llu b;
    for (int i = 0; i < npr; ++i) {
        b = (((seed << 5) ^ seed) >> 39);
        seed = (((seed & 18446744073709551614ULL) << 24) ^ b);

        device_array[tid + i * MT_RNG_COUNT] = seed;
    }

}

int main() {
    llu *device_array;
    
    llu *host_array;
    llu *host_copy;

    host_array = (llu *)malloc(RAND_N * sizeof(llu));
    host_copy = (llu *)malloc(RAND_N * sizeof(llu));
    cudaMalloc((void**)&device_array, RAND_N * sizeof(llu));

    // int iters = 100;
    // for (int i = 0; )
    RandomCT<<<32, 128>>>(device_array, N_PER_RNG);

    cudaMemcpy(host_copy, device_array, RAND_N * sizeof(llu), cudaMemcpyDeviceToHost);
    
    // for (int i = 0; i < 10; ++i) {
    //     printf("%llu\n", host_copy[i]);
    // }

    return 0;
}