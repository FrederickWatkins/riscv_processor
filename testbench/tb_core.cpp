#include <iostream>
#include <random>
#include <cstdint>
#include <cassert>
#include <fstream>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vcore.h"

#define MEM_SIZE 0x1000000

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
                    m_trace->dump(i);
                    m_trace->close();
                    return 1;
                }
                main_memory[data_addr+3] = data_out >> 24;
                main_memory[data_addr+2] = data_out >> 16;
                main_memory[data_addr+1] = data_out >> 8;
                main_memory[data_addr] = data_out;
                if(data_addr==0x500) {
                    printf("%i\n", data_out);
                }
            }
        }
        if(instr_addr >= MEM_SIZE) {
            m_trace->dump(i);
            m_trace->close();
            return 1;
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
    m_trace->close();
}