void __attribute__((naked)) _start(void) {
    __asm__ volatile (
        //"nop;"
        "li x2, 2000;"
        "tail main;"
    );
}

int square(int i);

void main(){
    volatile int*const p = (volatile int*)0x500;
    for(int i = 0; 1; i++){
        *p = square(i);
    }
}

int square(int i){
    return i+i;
}