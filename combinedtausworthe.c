#include <stdio.h>

typedef unsigned long long llu;

llu gen(llu *s) {
    llu b;
    b = (((*s << 5) ^ *s) >> 39);
    *s = (((*s & 18446744073709551614ULL) << 24) ^ b);
    return *s;
}

int main() {
    llu seed = 3423;
    for (int i = 0; i < 100; ++i) {
        gen(&seed);
        printf("%llu\n", seed);
    }
}
