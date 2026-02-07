#include <iostream>
#include <random>
#include <cstdint>
#include <cassert>
#include <fstream>
#include <vector>
#include <string.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vcore.h"

#define TEST_RESULTS_BASE 0x00002000 
#define MEM_SIZE 0x1000000

uint32_t expected_results[] = {
    0x12345E77, // [0]  ADDI (a + 0x7FF)
    0x12344E78, // [1]  ADDI (a - 0x800)
    0x00000000, // [2]  SLTI (a < 0x100) -> False
    0x00000001, // [3]  SLTIU (a < 0x7FFFFFFF) -> True
    0x12345987, // [4]  XORI
    0x12345679, // [5]  ORI
    0x00000228, // [6]  ANDI
    0x000000F0, // [7]  SLLI (0x8000000F << 4)
    0x08000000, // [8]  SRLI (Logical Shift Right)
    0xF8000000, // [9]  SRAI (Arithmetic Shift Right - Sign preserved)
    0xFFFFFFFF, // [10] ADD (0x55555555 + 0xAAAAAAAA)
    0xAAAAAAAB, // [11] SUB (0x55555555 - 0xAAAAAAAA)
    0xFFFFFFFF, // [12] XOR
    0xFFFFFFFF, // [13] OR
    0x00000000, // [14] AND
    0x00000000, // [15] SLT (Signed: Positive < Negative) -> False
    0x0000000B, // [16] branch_check (Sum of successful branches: 1 + 2 + 8)
    0x44332211, // [17] LW (Little-endian load)
    0x00006655, // [18] LH
    0xFFFFFF88, // [19] LB (Sign extended 0x88)
    0x00000088, // [20] LBU (Zero extended 0x88)
    0xABCDE000, // [21] LUI (Upper immediate)
    0xDEADBEEF  // [22] Final Success Marker
};

class WishboneSlave {
    public: 
        WishboneSlave(uint8_t* memory, unsigned int memory_size, int delay, int* curr_cycle, uint32_t* ADR,
                      uint8_t* SEL, unsigned char* WE, unsigned char* STB, unsigned char* CYC, uint32_t* DAT_W, uint32_t* DAT_R,
                      unsigned char* ACK){
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
        void read_from_port() {
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
        void write_to_port() {
            if(*STB && *CYC && !*WE) {
                if(*ADR >= memory_size - 4) {
                    printf("DUT attempted to read out of bounds on cycle %x at ADR %x\n", *curr_cycle, *ADR);
                }
                if(!handshake_active) {
                    last_handshake = *curr_cycle;
                    handshake_active = true;
                }
            }
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
        }
    private:
        // Config
        uint8_t* memory;
        unsigned int memory_size;
        int delay;
        int last_handshake;
        bool handshake_active;
        int* curr_cycle;
        // Wishbone outputs
        uint32_t* ADR;
        uint8_t* SEL;
        unsigned char* WE;
        unsigned char* STB;
        unsigned char* CYC;
        uint32_t* DAT_W;
        // Wishbone inputs
        uint32_t* DAT_R;
        unsigned char* ACK;
};

int main(int argc, char** argv) {
	VerilatedVcdC *m_trace = new VerilatedVcdC;

    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    Vcore* core = new Vcore{contextp};
    core->trace(m_trace, 99);
    m_trace->open("obj_dir/core.vcd");

    if(argc<=1){
        printf("Specify program\n");
        return 1;
    }
    std::ifstream file(argv[1], std::ios::binary);
    if(!file) {
        printf("Failed to find binary file %s\n", argv[1]);
        return 1;
    }
    uint8_t* main_memory = (uint8_t*)malloc(MEM_SIZE);
    file.read(reinterpret_cast<char*>(main_memory), MEM_SIZE);
    file.close();
    int curr_cycle = 0;

    WishboneSlave instr_port = WishboneSlave(
        main_memory, MEM_SIZE, 1, &curr_cycle, &core->INSTR_ADR, &core->INSTR_SEL, &core->INSTR_WE,
        &core->INSTR_STB, &core->INSTR_CYC, &core->INSTR_DAT_W, &core->INSTR_DAT_R, &core->INSTR_ACK
    );

    WishboneSlave data_port = WishboneSlave(
        main_memory, MEM_SIZE, 1, &curr_cycle, &core->DATA_ADR, &core->DATA_SEL, &core->DATA_WE,
        &core->DATA_STB, &core->DATA_CYC, &core->DATA_DAT_W, &core->DATA_DAT_R, &core->DATA_ACK
    );

    int clk;
    for(curr_cycle = 0; curr_cycle < 1000; curr_cycle++) {
        clk = curr_cycle % 2;
        contextp->timeInc(1);
        if(clk == 1) {
            instr_port.read_from_port();
            data_port.read_from_port();
        }
        core->clk = clk;
        core->eval();
        if(clk == 1) {
            instr_port.write_to_port();
            data_port.write_to_port();
        }
        core->eval();
        m_trace->dump(curr_cycle);
    }

    m_trace->close();
    if(strstr(argv[1], "stresstest")!=NULL) {
        int failed = 0;
        uint32_t* result = (uint32_t*)&main_memory[TEST_RESULTS_BASE];
        for(int i = 0; i < 23; i++) {
            if(result[i] != expected_results[i]) {
                printf("Test %i failed. %x != %x\n", i+1, result[i], expected_results[i]);
                failed++;
            }
        }
        if(failed==0) {
            printf("\033[32m");
        } else {
            printf("\033[31m");
        }
        printf("=== %i/23 core tests passed ===\033[0m\n", 23-failed);
    }
}