#include<stdint.h>

#define ADDRESS_BASE 0x00002000

int __mulsi3(int a, int b) {
    // Determine the sign of the result
    int res = 0;
    for(int i = 0; i<32; i++) {
        res += (b >> i)&1?a<<i:0;
    }
    return res;
}

int square(int i) {
    return i * i;
}

void main() {
    volatile int* i = (volatile int*)ADDRESS_BASE;
    *i = 2;
    while(*i<10000) *i = square(*i);
    return;
}
