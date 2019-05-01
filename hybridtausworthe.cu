#include <stdio.h>
#include <iostream>
#include <string>
#include <sstream>
using namespace std;

typedef unsigned long long llu;

int iAlignUp(int a, int b){
    return ((a % b) != 0) ?  (a - a % b + b) : a;
}

int iDivUp(int a, int b){
    return ((a % b) != 0) ? (a / b + 1) : (a / b);
}

#define MT_RNG_COUNT 2

// int    PATH_N = 1000000;
// int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
// int    RAND_N = MT_RNG_COUNT * N_PER_RNG;

// __global__ void RandomCT(llu *device_array, int npr) {
//     const int tid = blockDim.x * blockIdx.x + threadIdx.x;
    
//     llu seed = 10 * tid + 5;

//     llu b;
//     for (int i = 0; i < npr; ++i) {
//         b = (((seed << 5) ^ seed) >> 39);
//         seed = (((seed & 18446744073709551614ULL) << 24) ^ b);

//         device_array[tid + i * MT_RNG_COUNT] = seed;
//     }

// }

typedef struct {
    llu s1, s2, s3, s4;
} tauswortheState;


__device__ void lcg(llu *s, llu p, llu a, llu b) {
    *s = a * p + b;
}

__global__ void RandomHT(llu *device_array, int npr) {
    const int tid = blockDim.x * blockIdx.x + threadIdx.x;
    llu s1, s2, s3, s4;
    llu seed = 10 * tid + 129;
    
    lcg(&s1, seed, 1664525, 1013904223ULL);
    lcg(&s2, s1, 1664525, 1013904223ULL);
    lcg(&s3, s2, 1664525, 1013904223ULL);
    lcg(&s4, s3, 1664525, 1013904223ULL);
    
    llu b;
    for (int i = 0; i < 4; ++i) {
        b = (((s1 << 5) ^ s1) >> 39);
        s1 = (((s1 & 18446744073709551614ULL) << 24) ^ b);

        b = (((s2 << 19) ^ s2) >> 45);
        s2 = (((s2 & 18446744073709551552ULL) << 13) ^ b);

        b = (((s3 << 24) ^ s3) >> 48);
        s3 = (((s3 & 18446744073709551104ULL) << 7) ^ b);

        // s4 = lcg(s4, 1664525, 1013904223ULL);
        lcg(&s4, s4, 1664525, 1013904223ULL);
    }
    
    for (int i = 0; i < npr; ++i) {
        b = (((s1 << 5) ^ s1) >> 39);
        s1 = (((s1 & 18446744073709551614ULL) << 24) ^ b);

        b = (((s2 << 19) ^ s2) >> 45);
        s2 = (((s2 & 18446744073709551552ULL) << 13) ^ b);

        b = (((s3 << 24) ^ s3) >> 48);
        s3 = (((s3 & 18446744073709551104ULL) << 7) ^ b);

        lcg(&s4, s4, 1664525, 1013904223ULL);
        
        b = s1 ^ s2 ^ s3 ^ s4;
        device_array[tid + i * MT_RNG_COUNT] = b;
    }
    
}

int main() {
    for (int xx = 10; xx <= 10; xx *= 10) {
        ostringstream os;
        os << "RANDOMNUMBERS_" << xx << "_HT_GPU.txt";
        string x = os.str();
        // freopen(x.c_str(), "w", stdout);

        // freopen("HybridParallel.txt", "w", stdout);
        // for (int i = 10000; i <= 1000000000; i *= 10) {
        //     int    PATH_N = i;
        //     int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
        //     int    RAND_N = MT_RNG_COUNT * N_PER_RNG;

        //     printf("%d ", RAND_N);
        // }
        // printf("\n");
        // float ktime[6], tTime[6];

        // for (int i = 10000, j = 0; i <= 1000000000, j < 6; i *= 10, j++) {
            int    PATH_N = xx;
            int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
            int    RAND_N = MT_RNG_COUNT * N_PER_RNG;

            // cudaEvent_t start, stop, memstart, memstop;
            // cudaEventCreate(&memstart);
            // cudaEventCreate(&memstop);
            // cudaEventCreate(&start);
            // cudaEventCreate(&stop);

            llu *device_array;
            
            llu *host_array;
            llu *host_copy;

            host_array = (llu *)malloc(RAND_N * sizeof(llu));
            host_copy = (llu *)malloc(RAND_N * sizeof(llu));

            // cudaEventRecord(memstart);
            cudaMalloc((void**)&device_array, RAND_N * sizeof(llu));

            // int iters = 100;
            // for (int i = 0; )
            // cudaEventRecord(start);
            RandomHT<<<32, 128>>>(device_array, N_PER_RNG);
            // cudaEventRecord(stop);

            cudaMemcpy(host_copy, device_array, RAND_N * sizeof(llu), cudaMemcpyDeviceToHost);
            // cudaEventRecord(memstop);

            // cudaEventSynchronize(stop);
            // cudaEventSynchronize(memstop);
            
            for (int i = 0; i < RAND_N; ++i) {
                printf("%llu\n", host_copy[i]);
            }

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

            free(host_array); free(host_copy);
            cudaFree(device_array);
        // }

        // for (int i = 0; i < 6; ++i) 
        //     printf("%f ", ktime[i]);
        // printf("\n");
        // for (int i = 0; i < 6; ++i) 
        //     printf("%f ", tTime[i]);
        // printf("\n");
        
        // cudaEvent_t start, stop, memstart, memstop;
        // cudaEventCreate(&memstart);
        // cudaEventCreate(&memstop);
        // cudaEventCreate(&start);
        // cudaEventCreate(&stop);

        // llu *device_array;
        
        // llu *host_array;
        // llu *host_copy;

        // host_array = (llu *)malloc(RAND_N * sizeof(llu));
        // host_copy = (llu *)malloc(RAND_N * sizeof(llu));

        // cudaEventRecord(memstart);
        // cudaMalloc((void**)&device_array, RAND_N * sizeof(llu));

        // // int iters = 100;
        // // for (int i = 0; )
        // cudaEventRecord(start);
        // RandomHT<<<32, 128>>>(device_array, N_PER_RNG);
        // cudaEventRecord(stop);

        // cudaMemcpy(host_copy, device_array, RAND_N * sizeof(llu), cudaMemcpyDeviceToHost);
        // cudaEventRecord(memstop);

        // cudaEventSynchronize(stop);
        // cudaEventSynchronize(memstop);
        
        // // for (int i = 0; i < 10; ++i) {
        // //     printf("%llu\n", host_copy[i]);
        // // }

        // float kernelTime, totalTime;
        // cudaEventElapsedTime(&kernelTime, start, stop);
        // cudaEventElapsedTime(&totalTime, memstart, memstop);
        // kernelTime /= 1000.0f;
        // totalTime /= 1000.0f;
        
        // cout << "Time taken for " << RAND_N << " random numbers: \n";
        // cout << "Kernel Execution time: " << kernelTime << "s\n";
        // cout << "Overall Time: " << totalTime << "s\n";
        fclose(stdout);
    }

    return 0;
}
