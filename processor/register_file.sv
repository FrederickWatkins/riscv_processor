module register_file #(
    parameter addr_width = 5,
    parameter data_width = 32
)(
    input wire clk,
    input wire write_enable,
    
    input wire [addr_width-1:0] rs1_addr,
    output logic [data_width-1:0] rs1_data,

    input wire [addr_width-1:0] rs2_addr,
    output logic [data_width-1:0] rs2_data,

    input wire [addr_width-1:0] rd_addr,
    input wire [data_width-1:0] rd_data
);

    reg [data_width-1:0] ram [(1<<addr_width)-1:1];

    // Synchronous Write: Data is stored on the rising edge
    always @(posedge clk) begin
        if (write_enable && rd_addr != 0) begin
            ram[rd_addr] <= rd_data;
        end
    end

    // Asynchronous Read: Output changes immediately when read_addr changes
    always @(*) begin
        if (rs1_addr == 0) begin
            rs1_data = '0;
        end else begin
            rs1_data = ram[rs1_addr];
        end
        if (rs2_addr == 0) begin
            rs2_data = '0;
        end else begin
            rs2_data = ram[rs2_addr];
        end
    end
endmodule
