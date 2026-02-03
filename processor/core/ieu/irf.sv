// Integer register file
module irf #(
    parameter addr_width = 5,
    parameter XLEN = 32
)(
    input logic clk,

    input logic [addr_width-1:0] rs1_addr,
    output logic [XLEN-1:0] rs1_data,
    input logic [addr_width-1:0] rs2_addr,
    output logic [XLEN-1:0] rs2_data,
    input logic rd_we,
    input logic [addr_width-1:0] rd_addr,
    input logic [XLEN-1:0] rd_data
);
    logic [XLEN-1:0] ram [(1<<addr_width)-1:1];

    always @(*) begin
        rs1_data = (rs1_addr == 0) ? '0 : ram[rs1_addr];
        rs2_data = (rs2_addr == 0) ? '0 : ram[rs2_addr];
    end

    always @(posedge clk) begin
        if (rd_we && (rd_addr != 0)) begin
            ram[rd_addr] <= rd_data;
        end
    end
endmodule
