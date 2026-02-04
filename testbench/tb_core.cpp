#include <iostream>
#include <random>
#include <cstdint>
#include <cassert>
#include <fstream>
#include <vector>
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
    0xAAAAAAAA, // [11] SUB (0x55555555 - 0xAAAAAAAA)
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

int main(int argc, char** argv) {
	VerilatedVcdC *m_trace = new VerilatedVcdC;

    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    Vcore* core = new Vcore{contextp};
    core->trace(m_trace, 99);
    m_trace->open("obj_dir/core.vcd");
    uint instr_addr=0;
    uint data_addr=0;
    int data_out=0;
    int data_we=0;
    std::ifstream file("obj_dir/square.bin", std::ios::binary);
    if(!file) {
        printf("Failed to find binary file");
        return 1;
    }
    unsigned char* main_memory = (unsigned char*)malloc(MEM_SIZE);
    file.read(reinterpret_cast<char*>(main_memory), MEM_SIZE);
    file.close();
    core->instr_in = main_memory[3] << 24 | main_memory[2] << 16 | main_memory[1] << 8 | main_memory[0];
    core->data_in = main_memory[3] << 24 | main_memory[2] << 16 | main_memory[1] << 8 | main_memory[0];
    for(int i = 1; i < 1000; i++) {
        int clk = i % 2;
        contextp->timeInc(1);
        if(clk==1){
            instr_addr = core->instr_addr;
            data_addr = core->data_addr;
            data_out = core->data_out;
            data_we = core->data_we;
            if(data_we){
                if(data_addr >= MEM_SIZE) {
                    printf("Attempted to write out of bounds at address %x at instruction %x on cycle %u\n", data_addr, instr_addr, i);
                    m_trace->dump(i);
                    m_trace->close();
                    return 0;
                }
                main_memory[data_addr+3] = data_out >> 24;
                main_memory[data_addr+2] = data_out >> 16;
                main_memory[data_addr+1] = data_out >> 8;
                main_memory[data_addr] = data_out;
            }
        }
        if(instr_addr >= MEM_SIZE) {
            printf("Instruction pointer out of bounds at %x on cycle %u\n", instr_addr, i);
            m_trace->dump(i);
            m_trace->close();
            return 0;
        }
        core->clk = clk;
        core->eval();
        if(clk==1){
            core->instr_in = main_memory[instr_addr+3] << 24 | main_memory[instr_addr+2] << 16 | main_memory[instr_addr+1] << 8 | main_memory[instr_addr];
            if(data_addr < MEM_SIZE) {
                core->data_in = main_memory[data_addr+3] << 24 | main_memory[data_addr+2] << 16 | main_memory[data_addr+1] << 8 | main_memory[data_addr];
            }
        }
        core->eval();
        m_trace->dump(i);
    }
    uint32_t* result = (uint32_t*)&main_memory[TEST_RESULTS_BASE];
    for(int i = 0; i < 23; i++) {
        if(result[i] != expected_results[i]) {
            printf("Test %i failed. %x != %x\n", i+1, result[i], expected_results[i]);
        }
    }
    m_trace->close();
}