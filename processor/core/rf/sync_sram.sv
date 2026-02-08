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
    logic [XLEN-1:0] ram [(1<<depth)-1:1];

    always @(posedge clk) begin
        if(rd_we && rd_addr != 0) ram[rd_addr] <= rd_data;
        if(rs1_addr != 0) rs1_data <= ram[rs1_addr];
        else rs1_data <= 0;
        if(rs2_addr != 0) rs2_data <= ram[rs2_addr];
        else rs2_data <= 0;
    end
endmodule
