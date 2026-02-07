// Register file
module rf #(
    parameter XLEN(XLEN),
) (
    input logic clk,
    // Inputs
    input logic [31:2] rs_instr,
    input logic [31:2] rd_instr,
    input logic [XLEN-1:0] ieu_result,
    input logic [XLEN-1:0] lsu_data,
    // Outputs
    output logic [XLEN-1:0] rs1_data,
    output logic [XLEN-1:0] rs2_data
);

endmodule