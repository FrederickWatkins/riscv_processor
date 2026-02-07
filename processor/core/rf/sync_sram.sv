module sync_sram #(
    parameter XLEN = 32,
    parameter depth = 5
) (
    input logic clk,

    input logic [depth-1:0] rs1_addr,
    input logic [depth-1:0] rs2_addr,
    input logic rd_we,
    input logic [depth-1:0] rd_addr,
    input logic [XLEN-1:0] rd_data,

    output logic [XLEN-1:0] rs1_data,
    output logic [XLEN-1:0] rs2_data
);
    logic [XLEN-1:0] ram [(1<<depth)-1:0];

    always @(posedge clk) begin
        if(rd_we) ram[rd_addr] <= rd_data;
        rs1_data <= ram[rs1_addr];
        rs2_data <= ram[rs2_addr];
    end
endmodule
