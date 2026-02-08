// Shim because verilator can't handle interfaces
module core_shim #(
    parameter XLEN = 32
) (
    input logic clk,
    // Instruction port
    output logic [XLEN-1:0] INSTR_ADR,
    output logic [XLEN/8-1:0] INSTR_SEL,
    output logic INSTR_WE,
    output logic INSTR_STB,
    output logic INSTR_CYC,
    output logic [XLEN-1:0] INSTR_DAT_W,
    input logic [XLEN-1:0] INSTR_DAT_R,
    input logic INSTR_ACK,
    // Data port
    output logic [XLEN-1:0] DATA_ADR,
    output logic [XLEN/8-1:0] DATA_SEL,
    output logic DATA_WE,
    output logic DATA_STB,
    output logic DATA_CYC,
    output logic [XLEN-1:0] DATA_DAT_W,
    input logic [XLEN-1:0] DATA_DAT_R,
    input logic DATA_ACK
);
    wishbone #(.XLEN(XLEN)) instr_bus();

    wishbone #(.XLEN(XLEN)) data_bus();

    assign INSTR_ADR = instr_bus.ADR;
    assign INSTR_SEL = instr_bus.SEL;
    assign INSTR_WE = instr_bus.WE;
    assign INSTR_STB = instr_bus.STB;
    assign INSTR_CYC = instr_bus.CYC;
    assign INSTR_DAT_W = instr_bus.DAT_W;

    assign DATA_ADR = data_bus.ADR;
    assign DATA_SEL = data_bus.SEL;
    assign DATA_WE = data_bus.WE;
    assign DATA_STB = data_bus.STB;
    assign DATA_CYC = data_bus.CYC;

    always @(posedge clk) begin
        instr_bus.DAT_R <= INSTR_DAT_R;
        instr_bus.ACK <= INSTR_ACK;
        data_bus.DAT_R <= DATA_DAT_R;
        data_bus.ACK <= DATA_ACK;
    end
    assign DATA_DAT_W = data_bus.DAT_W;

    core #(
        .XLEN(XLEN)
    ) core (
        .clk,

        .instr_bus(instr_bus.MASTER),
        .data_bus(data_bus.MASTER)
    );
endmodule
