// RV32IC core

module core #(
    parameter XLEN = 32
) (
    input logic clk,
    // Instruction port
    output logic [XLEN-1:0] instr_addr,
    input logic [31:0] instr_in,
    // Data port
    output logic data_we,
    output logic [XLEN-1:0] data_addr,
    output logic [XLEN-1:0] data_out,
    input logic [XLEN-1:0] data_in
);
    logic stall, je, ieu_we, ieu_passthrough;
    logic [29:0] fetched_instr;
    logic [XLEN-1:0] ja, curr_pc, inc_pc, ieu_result, ieu_reg, rd_data;

    ifu #(
        .XLEN(XLEN)
    ) ifu (
        .clk,
        .stall,
        .je,
        .ja,
        .instr_in,

        .instr_out(fetched_instr),
        .curr_pc,
        .inc_pc,
        .next_pc(instr_addr)
    );

    ieu #(
        .XLEN(XLEN)
    ) ieu (
        .clk,
        .instr(fetched_instr),
        .curr_pc,
        .inc_pc,
        .rd_data,

        .stall,
        .je,
        .ja,
        .result(ieu_result),
        .reg_out(ieu_reg),
        .mm_we(ieu_we),
        .passthrough(ieu_passthrough)
    );

    mmu #(
        .XLEN(XLEN)
    ) mmu (
        .clk,
        .ieu_we,
        .ieu_passthrough,
        .ieu_reg,
        .ieu_result,
        .data_in,
        .data_we,
        .data_addr,
        .data_out,
        .rd_data
    );
endmodule
