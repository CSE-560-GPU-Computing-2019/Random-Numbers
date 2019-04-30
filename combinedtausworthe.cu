#include <stdio.h>
#include <iostream>
#include <string>
#include <sstream>
#include <iostream>
using namespace std;

typedef unsigned long long llu;

int iAlignUp(int a, int b){
    return ((a % b) != 0) ?  (a - a % b + b) : a;
}

int iDivUp(int a, int b){
    return ((a % b) != 0) ? (a / b + 1) : (a / b);
}

#define MT_RNG_COUNT 4096

// const int    PATH_N = 1000000;
// const int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
// const int    RAND_N = MT_RNG_COUNT * N_PER_RNG;

__global__ void RandomCT(llu *device_array, int npr) {
    const int tid = blockDim.x * blockIdx.x + threadIdx.x;
    
    llu seed = 23 * tid + 200;
    llu b;

    for (int i = 0; i < 4; ++i) {
        b = (((seed << 5) ^ seed) >> 39);
        seed = (((seed & 18446744073709551614ULL) << 24) ^ b);
    }

    for (int i = 0; i < npr; ++i) {
        b = (((seed << 5) ^ seed) >> 39);
        seed = (((seed & 18446744073709551614ULL) << 24) ^ b);

        device_array[tid + i * MT_RNG_COUNT] = seed;
    }

}

int main() {
    // freopen("CombinedParallel.txt", "w", stdout);
    for (int i = 1000; i <= 1000; i *= 10) {
        ostringstream os;
        os << "RANDOMNUMBERS_" << i << "_CT_GPU.txt";
        string x = os.str();
        freopen(x.c_str(), "w", stdout);
        // for (int i = 10000; i <= 1000000000; i *= 10) {
        //     int    PATH_N = i;
        //     int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
        //     int    RAND_N = MT_RNG_COUNT * N_PER_RNG;

        //     printf("%d ", RAND_N);
        // }
        // printf("\n");
        // float ktime[6], tTime[6];
        // for (int i = 10000, j = 0; i <= 1000000000, j < 6; i *= 10, j++) {
            int    PATH_N = i;
            int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
            int    RAND_N = MT_RNG_COUNT * N_PER_RNG;


            llu *device_array;
            // cudaEvent_t start, stop, memstart, memstop;
            // cudaEventCreate(&memstart);
            // cudaEventCreate(&memstop);
            // cudaEventCreate(&start);
            // cudaEventCreate(&stop);
            
            llu *host_array;
            llu *host_copy;

            host_array = (llu *)malloc(RAND_N * sizeof(llu));
            host_copy = (llu *)malloc(RAND_N * sizeof(llu));
            // cudaEventRecord(memstart);
            cudaMalloc((void**)&device_array, RAND_N * sizeof(llu));

            // int iters = 100;
            // for (int i = 0; )
            // cudaEventRecord(start);
            RandomCT<<<32, 128>>>(device_array, N_PER_RNG);
            // cudaEventRecord(stop);

            cudaMemcpy(host_copy, device_array, RAND_N * sizeof(llu), cudaMemcpyDeviceToHost);
            // cudaEventRecord(memstop);

            // cudaEventSynchronize(stop);
            // cudaEventSynchronize(memstop);
            

            // float kernelTime, totalTime;
            // cudaEventElapsedTime(&kernelTime, start, stop);
            // cudaEventElapsedTime(&totalTime, memstart, memstop);
            // kernelTime /= 1000.0f;
            // totalTime /= 1000.0f;
            

            // cout << "Time taken for " << RAND_N << " random numbers: \n";
            // cout << "Kernel Execution time: " << kernelTime << "s\n";
            // cout << "Overall Time: " << totalTime << "s\n";
            // ktime[j] = kernelTime;
            // tTime[j] = totalTime;


            
            // for (int i = 0; i < 10; ++i) {
            //     printf("%llu\n", host_copy[i]);
            // }


            for (int j = 0; j < RAND_N; ++j) {
                printf("%llu\n", host_copy[j]);
            }

            free(host_array); free(host_copy);
            cudaFree(device_array);
        // }
        // for (int i = 0; i < 6; ++i) 
        //     printf("%f ", ktime[i]);
        // printf("\n");
        // for (int i = 0; i < 6; ++i) 
        //     printf("%f ", tTime[i]);
        // printf("\n");
        fclose(stdout);
    }

    return 0;
}
