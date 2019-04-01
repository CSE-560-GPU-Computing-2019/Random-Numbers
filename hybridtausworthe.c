#include <stdio.h>

typedef unsigned long long llu;

typedef struct {
    llu s1, s2, s3, s4;
} tauswortheState;

llu lcg(llu *s, llu a, llu b) {
    *s = a * *s + b;
    return *s;
}

llu gen(tauswortheState *s) {
    llu b;
    b = (((s->s1 << 5) ^ s->s1) >> 39);
    s->s1 = (((s->s1 & 18446744073709551614ULL) << 24) ^ b);

    b = (((s->s2 << 19) ^ s->s2) >> 45);
    s->s2 = (((s->s2 & 18446744073709551552ULL) << 13) ^ b);

    b = (((s->s3 << 24) ^ s->s3) >> 48);
    s->s3 = (((s->s3 & 18446744073709551104ULL) << 7) ^ b);

    lcg(s, 1664525, 1013904223ULL);

    return s->s1 ^ s->s2 ^ s->s3 ^ s->s4;
}

void initstate(tauswortheState *s, llu seed) {

}

int main() {
    llu seed = 3423;
    for (int i = 0; i < 100; ++i) {
        gen(&seed);
        printf("%llu\n", seed);
    }
}
