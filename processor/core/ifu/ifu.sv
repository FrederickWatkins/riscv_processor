// Instruction fetch unit
module ifu #(
    parameter XLEN = 32
) (
    input logic clk,
    input logic stall,
    input logic je,
    input logic [XLEN-1:0] ja,
    input logic [31:0] instr_in,

    output logic [31:2] instr_out,
    output logic [XLEN-1:0] curr_pc,
    output logic [XLEN-1:0] inc_pc,
    output logic [XLEN-1:0] next_pc
);
    logic compressed;

    pc #(
        .XLEN(XLEN)
    ) pc (
        .clk,

        .stall,
        .compressed,
        .je,
        .ja,

        .curr_pc,
        .inc_pc,
        .next_pc
    );

    decomp decomp (
        .instr_in,
        .compressed,
        .instr_out
    );
endmodule
