#include <stdio.h>
#include <ctime>

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


llu gen(llu *s) {
    llu b;
    b = (((*s << 5) ^ *s) >> 39);
    *s = (((*s & 18446744073709551614ULL) << 24) ^ b);
    return *s;
}

int main() {
    llu seed = 3423;
    const clock_t begin_time = clock();

    for (int i = 0; i < RAND_N; ++i) {
        gen(&seed);
        // printf("%llu\n", seed);
    }

    float runTime = (float)( clock() - begin_time ) /  CLOCKS_PER_SEC;
    printf("Time for generating %d random numbers on CPU: %fs\n\n", RAND_N, runTime);
}
