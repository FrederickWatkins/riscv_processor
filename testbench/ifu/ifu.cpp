#include <fstream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vifu.h"
#include "../utils/wishbone.h"

#define MEM_SIZE 0x1000000

int main(int argc, char **argv)
{
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    Verilated::traceEverOn(true);

    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    Vifu *ifu = new Vifu{contextp};

    ifu->trace(m_trace, 99);
    m_trace->open("obj_dir/ifu.vcd");

    if (argc <= 1)
    {
        printf("Specify program\n");
        return 1;
    }
    std::ifstream file(argv[1], std::ios::binary);
    if (!file)
    {
        printf("Failed to find binary file %s\n", argv[1]);
        return 1;
    }
    uint8_t *main_memory = (uint8_t *)malloc(MEM_SIZE);
    file.read(reinterpret_cast<char *>(main_memory), MEM_SIZE);
    file.close();
    int curr_cycle = 0;

    printf("%x\n", main_memory[4]);

    ifu->jack = 0;
    int clk;
    int prev_clk;
    for (curr_cycle = 0; curr_cycle < 500; curr_cycle++)
    {
        prev_clk = clk;
        clk = curr_cycle % 2;
        contextp->timeInc(1);
        ifu->clk = clk;
        if (clk == 1)
        {
            if (ifu->instr_re)
            {
                ifu->valid = 1;
                ifu->instr_data = 0;
                for (int i = 0; i < 4; i++)
                {
                    if ((ifu->sel >> i) & 1)
                    {
                        ifu->instr_data |= (uint32_t)main_memory[ifu->instr_addr + i] << (i * 8);
                    }
                }
            } else {
                ifu-> valid = 0;
            }
            if(curr_cycle==15) {
                ifu->valid = 0;
            }
            else if(curr_cycle==43) {
                ifu->ja = 0x44;
                ifu->je = 1;
                ifu->jack = 1;
            } else if (curr_cycle==55) {
                ifu->ja = 0x4c;
                ifu->je = 1;
                ifu->jack = 1;
            } else {
                ifu->ja = 0;
                ifu->je = 0;
                ifu->jack = 0;
            }
        }
        ifu->eval();
        m_trace->dump(curr_cycle);
    }
    m_trace->close();
}