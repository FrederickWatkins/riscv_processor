// Shim because verilator can't handle interfaces
module core_shim #(
    parameter XLEN = 32
) (
    input logic clk,
    // Instruction port
    output logic [XLEN-1:0] instr_addr,
    input logic [31:0] instr_in,
    // Data port
    output logic [XLEN-1:0] ADR,
    output logic [XLEN/8-1:0] SEL,
    output logic WE,
    output logic STB,
    output logic [XLEN-1:0] DAT_W,
    input logic [XLEN-1:0] DAT_R,
    input logic ACK
);
    wishbone #(.XLEN(XLEN)) mm_bus();

    assign ADR = mm_bus.ADR;
    assign SEL = mm_bus.SEL;
    assign WE = mm_bus.WE;
    assign STB = mm_bus.STB;
    assign DAT_W = mm_bus.DAT_W;
    assign mm_bus.DAT_R = DAT_R;
    assign mm_bus.ACK = ACK;

    core #(
        .XLEN(XLEN)
    ) core (
        .clk,
        .instr_addr,
        .instr_in,
        .mm_bus(mm_bus.MASTER)
    );
endmodule
