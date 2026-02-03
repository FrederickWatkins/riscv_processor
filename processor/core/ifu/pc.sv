// Program counter
module pc #(
    parameter XLEN = 32
) (
    input logic clk,

    input logic stall,
    input logic compressed,
    input logic je,
    input logic [XLEN-1:0] ja,

    output logic [XLEN-1:0] curr_pc,
    output logic [XLEN-1:0] inc_pc,
    output logic [XLEN-1:0] next_pc
);
    assign inc_pc = curr_pc + (compressed?2:4);
    assign next_pc = je?ja:inc_pc;

    always @(posedge clk) begin
        if(!stall) curr_pc <= next_pc;
    end
endmodule
