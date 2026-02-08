#include <iostream>
#include "wishbone.h"

WishboneSlave::WishboneSlave(
    uint8_t* memory, unsigned int memory_size, int delay, int* curr_cycle, uint32_t* ADR,
    uint8_t* SEL, unsigned char* WE, unsigned char* STB, unsigned char* CYC, uint32_t* DAT_W, uint32_t* DAT_R,
    unsigned char* ACK
){
    this->memory = memory;
    this->memory_size = memory_size;
    this->delay = delay;
    this->last_handshake = -delay - 1;
    this->handshake_active = false;
    this->curr_cycle = curr_cycle;
    this->ADR = ADR;
    this->SEL = SEL;
    this->WE = WE;
    this->STB = STB;
    this->CYC = CYC;
    this->DAT_W = DAT_W;
    this->DAT_R = DAT_R;
    this->ACK = ACK;
}
void WishboneSlave::read_from_port() {
    if(*STB && *CYC && *WE) {
        if(*ADR >= memory_size - 4) {
            printf("DUT attempted to write out of bounds on cycle %x at ADR %x\n", *curr_cycle, *ADR);
        }
        for(int i = 0; i < 4; i++) {
            if((*SEL >> i) & 1) {
                memory[*ADR + i] = (*DAT_W>>8) & 0xFF;
            }
        }
        if(!handshake_active) {
            last_handshake = *curr_cycle;
            handshake_active = true;
        }
    }
}
void WishboneSlave::write_to_port() {
    if(handshake_active && *curr_cycle - last_handshake >= delay) {
        *DAT_R = 0;
        for(int i = 0; i < 4; i++) {
            if((*SEL >> i) & 1) {
                *DAT_R |= (uint32_t)memory[*ADR + i] << (i * 8);
                if(*ADR == 4) printf("%x\n", *DAT_R);
            }
        }
        *ACK = 1;
        handshake_active = false;
    } else {
        *ACK = 0;
    }
    if(*STB && *CYC && !*WE) {
        if(*ADR >= memory_size - 4) {
            printf("DUT attempted to read out of bounds on cycle %x at ADR %x\n", *curr_cycle, *ADR);
        }
        if(!handshake_active) {
            last_handshake = *curr_cycle;
            handshake_active = true;
        }
    }
}
