// Memory management unit
module mmu #(
    parameter XLEN = 32
) (
    input logic clk,

    input logic ieu_we,
    input logic ieu_passthrough,
    input logic [XLEN-1:0] ieu_reg,
    input logic [XLEN-1:0] ieu_result,

    input logic [XLEN-1:0] data_in,

    output logic data_we,
    output logic [XLEN-1:0] data_addr,
    output logic [XLEN-1:0] data_out,

    output logic [XLEN-1:0] rd_data
);
    assign data_addr = ieu_result;
    
    logic ieu_passthrough_d;
    logic [XLEN-1:0] ieu_result_d;

    always @(posedge clk) begin
        ieu_passthrough_d <= ieu_passthrough;
        ieu_result_d <= ieu_result;
    end

    always @(*) begin
        data_we = 0;
        data_out = 'x;
        if(ieu_we) begin
            data_we = 1;
            data_out = ieu_reg;
        end
    end

    always @(*) begin
        rd_data = data_in;
        if(ieu_passthrough_d) rd_data = ieu_result_d;
    end


endmodule
