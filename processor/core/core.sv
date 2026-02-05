// RV32IC core

module core #(
    parameter XLEN = 32
) (
    input logic clk,
    // Instruction port
    output logic [XLEN-1:0] instr_addr,
    input logic [31:0] instr_in,
    // Data port
    wishbone.MASTER mm_bus
);
    logic stall, je, ieu_we, ieu_re;
    logic [29:0] fetched_instr;
    logic [XLEN-1:0] ja, curr_pc, inc_pc, ieu_result, ieu_reg, rd_data;
    logic [2:0] funct3;

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
        .funct3,
        .result(ieu_result),
        .reg_out(ieu_reg),
        .mm_we(ieu_we),
        .mm_re(ieu_re)
    );

    lsu #(
        .XLEN(XLEN)
    ) lsu (
        .clk,
        .ieu_we,
        .ieu_re,
        .funct3,
        .ieu_reg,
        .ieu_result,
        .rd_data,
        .mm_bus
    );
endmodule
