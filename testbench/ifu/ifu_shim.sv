// Shim because verilator can't handle interfaces
module ifu_shim #(
    parameter XLEN = 32
) (
    input logic clk,
    // Instruction port
    output logic [XLEN-1:0] instr_addr,
    output logic instr_re,
    output logic [3:0] sel,
    input logic valid,
    input logic [31:0] instr_data,
    input logic stall, jack, je,
    input logic [XLEN-1:0] ja,

    // Outputs
    output logic [31:2] instr_out,
    output logic [XLEN-1:0] curr_pc, inc_pc
);
    wishbone #(.XLEN(XLEN)) instr_bus();

    assign instr_addr = instr_bus.ADR;
    assign sel = instr_bus.SEL;
    assign instr_re = instr_bus.STB & instr_bus.CYC;

    always @(posedge clk) begin
        if(instr_re & valid) begin
            instr_bus.ACK <= 1;
            instr_bus.DAT_R <= instr_data;
        end
        else begin
            instr_bus.ACK <= 0;
        end
    end

    logic stalled;

    ifu #(
        .XLEN(XLEN)
    ) ifu (
        .clk,

        .instr_bus(instr_bus.MASTER),
        // Inputs
        .stall(stall | stalled),
        .jack,
        .je,
        .ja,
        // Ouputs
        .stalled,
        .instr_out,
        .curr_pc,
        .inc_pc
    );
endmodule
