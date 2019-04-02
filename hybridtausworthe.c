#include <stdio.h>

typedef unsigned long long llu;

typedef struct {
    llu s1, s2, s3, s4;
} tauswortheState;

llu lcg(llu s, llu a, llu b) {
    llu x = a * s + b;
    return x;
}

llu gen(tauswortheState *s) {
    llu b;
    b = (((s->s1 << 5) ^ s->s1) >> 39);
    s->s1 = (((s->s1 & 18446744073709551614ULL) << 24) ^ b);

    b = (((s->s2 << 19) ^ s->s2) >> 45);
    s->s2 = (((s->s2 & 18446744073709551552ULL) << 13) ^ b);

    b = (((s->s3 << 24) ^ s->s3) >> 48);
    s->s3 = (((s->s3 & 18446744073709551104ULL) << 7) ^ b);

    s->s4 = lcg(s->s4, 1664525, 1013904223ULL);

    return s->s1 ^ s->s2 ^ s->s3 ^ s->s4;
}

void initstate(tauswortheState *s, llu seed) {
    s->s1 = lcg(seed, 1664525, 1013904223ULL);
    if (s->s1 <= 128ULL) s->s1 += 128ULL;

    s->s2 = lcg(s->s1, 1664525, 1013904223ULL);
    if (s->s2 <= 128ULL) s->s2 += 128ULL;

    s->s3 = lcg(s->s2, 1664525, 1013904223ULL);
    if (s->s3 <= 128ULL) s->s3 += 128ULL;

    s->s4 = lcg(s->s3, 1664525, 1013904223ULL);
    if (s->s4 <= 128ULL) s->s4 += 128ULL;

    // Warm up
    gen(s);
    gen(s);
    gen(s);
}

int main() {
    llu seed = 1232;
    tauswortheState *state = (tauswortheState *)malloc(sizeof(tauswortheState));;
    initstate(state, seed);
    llu randNum;
    for (int i = 0; i < 10; ++i) {
        randNum = gen(state);
        printf("%llu\n", randNum);
    }
}
