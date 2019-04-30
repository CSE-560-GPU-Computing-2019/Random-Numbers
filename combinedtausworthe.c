#include <stdio.h>
#include <ctime>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <sstream>
using namespace std;

typedef unsigned long long llu;

int iAlignUp(int a, int b){
    return ((a % b) != 0) ?  (a - a % b + b) : a;
}

int iDivUp(int a, int b){
    return ((a % b) != 0) ? (a / b + 1) : (a / b);
}

#define MT_RNG_COUNT 4096

// int    PATH_N = 10000;
// int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
// int    RAND_N = MT_RNG_COUNT * N_PER_RNG;


llu gen(llu *s) {
    llu b;
    b = (((*s << 5) ^ *s) >> 39);
    *s = (((*s & 18446744073709551614ULL) << 24) ^ b);
    return *s;
}

int main() {
    for (int i = 100; i <= 100000; i *= 10) {
        ostringstream os;
        os << "RANDOMNUMBERS_" << i << "_CT_CPU.txt";
        string x = os.str();
        freopen(x.c_str(), "w", stdout);
        // for (int i = 10000; i <= 1000000000; i *= 10) {
        //     int    PATH_N = i;
        //     int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
        //     int    RAND_N = MT_RNG_COUNT * N_PER_RNG;

        //     printf("%d ", RAND_N);
        // }
        // printf("\n");
        // for (int i = 10000; i <= 1000000000; i *= 10) {
        //     int    PATH_N = i;
        //     int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
        //     int    RAND_N = MT_RNG_COUNT * N_PER_RNG;
        //     llu seed = 3423;
        //     const clock_t begin_time = clock();
        //     // llu *randnums = (llu*)malloc(RAND_N * sizeof(llu));

        //     for (int i = 0; i < RAND_N; ++i) {
        //         // randnums[i] = gen(&seed);
        //         gen(&seed);
        //         // printf("%llu\n", seed);
        //     }

        //     float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
        //     // printf("Time for generating %d random numbers on CPU: %fs\n\n", RAND_N, runTime);
        //     printf("%f ", runTime);
        // }
        // printf("\n");
        // for (int i = 10000; i <= 1000000000; i *= 10) {
        //     int    PATH_N = i;
        //     int N_PER_RNG = iAlignUp(iDivUp(PATH_N, MT_RNG_COUNT), 2);
        //     int    RAND_N = MT_RNG_COUNT * N_PER_RNG;
        //     llu seed = 3423;
        //     const clock_t begin_time = clock();
        //     llu *randnums = (llu*)malloc(RAND_N * sizeof(llu));

        //     for (int i = 0; i < RAND_N; ++i) {
        //         randnums[i] = gen(&seed);
        //         // gen(&seed);
        //         // printf("%llu\n", seed);
        //     }

        //     float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
        //     // printf("Time for generating %d random numbers on CPU: %fs\n\n", RAND_N, runTime);
        //     printf("%f ", runTime);
        // }
        // printf("\n");
        llu seed = 3413;
        // const clock_t begin_time = clock();
        // llu *randnums = (llu*)malloc(RAND_N * sizeof(llu));
        llu max = 0;

        for (int j = 0; j < i; ++j) {
            // randnums[i] = gen(&seed);
            gen(&seed);
            printf("%llu\n", seed);
            // if (seed > max) max = seed;
        }
        fclose(stdout);
    }

    // printf("%llu\n", seed);

    // float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
    // printf("Time for generating %d random numbers on CPU: %fs\n\n", RAND_N, runTime);
}
