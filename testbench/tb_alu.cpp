#include <iostream>
#include <random>
#include <cstdint>
#include <cassert>
#include <verilated.h>
#include "Valu.h"

int main(int argc, char** argv) {
    Verilated::traceEverOn(true);

    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(true);
    Valu* alu = new Valu{contextp};
    auto run_test = [&](int op1, int op2, int funct3, int invert){
        alu->operand_1 = op1;
        alu->operand_2 = op2;
        alu->funct3 = funct3;
        alu->invert = invert;
        alu->eval();
        return alu->result;
    };
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<int32_t> distrib; 
    auto run_test_suite = [&](int op1, int op2){
        auto actual = run_test(op1, op2, 0b000, 0);
        auto expected = op1 + op2;
        if(actual != expected){ // ADD
            std::cerr << "Addition test failed for " << op1 << " + " << op2
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(op1, op2, 0b000, 1);
        expected = op1 - op2;
        if(actual != expected){ // SUB
            std::cerr << "Subtraction test failed for " << op1 << " - " << op2
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(op1, op2, 0b001, 0);
        expected = op1 << (op2 & 0x1F);
        if(actual != expected){ // SL
            std::cerr << "Shift Left test failed for " << op1 << " << " << (op2 & 0x1F)
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(op1, op2, 0b010, 0);
        expected = (op1 < op2) ? 1 : 0;
        if(actual != expected){ // SLT
            std::cerr << "SLT test failed for " << op1 << " < " << op2
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(uint32_t(op1), uint32_t(op2), 0b011, 0);
        expected = (uint32_t(op1) < uint32_t(op2)) ? 1 : 0;
        if(actual != expected){ // SLTU
            std::cerr << "SLTU test failed for " << uint32_t(op1) << " < " << uint32_t(op2)
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(uint32_t(op1), uint32_t(op2), 0b100, 0);
        expected = uint32_t(op1) ^ uint32_t(op2);
        if(actual != expected){ // XOR
            std::cerr << "XOR test failed for " << uint32_t(op1) << " ^ " << uint32_t(op2)
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(uint32_t(op1), uint32_t(op2), 0b101, 0);
        expected = uint32_t(op1) >> (op2 & 0x1F);
        if(actual != expected){ // SRL
            std::cerr << "Shift Right Logical test failed for " << uint32_t(op1) << " >> " << (op2 & 0x1F)
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(int32_t(op1), int32_t(op2), 0b101, 1);
        expected = int32_t(op1) >> (op2 & 0x1F);
        if(actual != expected){ // SRA
            std::cerr << "Shift Right Arithmetic test failed for " << int32_t(op1) << " >>> " << (op2 & 0x1F)
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(uint32_t(op1), uint32_t(op2), 0b110, 0);
        expected = uint32_t(op1) | uint32_t(op2);
        if(actual != expected){ // OR
            std::cerr << "OR test failed for " << uint32_t(op1) << " | " << uint32_t(op2)
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        actual = run_test(uint32_t(op1), uint32_t(op2), 0b111, 0);
        expected = uint32_t(op1) & uint32_t(op2);
        if(actual != expected){ // AND
            std::cerr << "AND test failed for " << uint32_t(op1) << " & " << uint32_t(op2)
                      << " | Expected: " << expected << " Actual: " << actual << std::endl;
            return 1;
        }
        return 0;
    };
    for(int i = 0; i < 10000; i++){
        int32_t op1 = distrib(gen); 
        int32_t op2 = distrib(gen);
        if(run_test_suite(op1, op2)){
            return 1;
        }
    }
    if(run_test_suite(-1, 1)){
        return 1;
    }
    int32_t op1x[] = {0, -1, 1, INT32_MAX, INT32_MIN}; 
    int32_t op2x[] = {0, -1, 1, INT32_MAX, INT32_MIN};
    for(auto op1 : op1x){
        for(auto op2 : op2x){
            if(run_test_suite(op1, op2)){
                return 1;
            }
        }
    }
    std::cout << "All ALU tests passed" << std::endl;
    return 0;
}