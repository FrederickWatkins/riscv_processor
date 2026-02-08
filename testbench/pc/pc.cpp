#include <fstream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vpc.h"
#include "../utils/wishbone.h"

#define MEM_SIZE 0x1000000

int main(int argc, char** argv) {
	VerilatedVcdC *m_trace = new VerilatedVcdC;
    Verilated::traceEverOn(true);

    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    Vpc* pc = new Vpc{contextp};

    pc->trace(m_trace, 99);
    m_trace->open("obj_dir/pc.vcd");
    int curr_cycle = 0;

    pc->compressed = 0;
    pc->je = 0;
    pc->ja = 0;
    int stall[10] = {0, 0, 0, 1, 1, 0, 0, 1, 0, 1};

    int clk;
    for(curr_cycle = 0; curr_cycle < 18; curr_cycle++) {
        contextp->timeInc(1);
        pc->clk = curr_cycle % 2;
        pc->eval();
        if(clk == 0) {
            pc->stall = stall[curr_cycle/2];
        }
        m_trace->dump(curr_cycle);
    }
    m_trace->close();
}