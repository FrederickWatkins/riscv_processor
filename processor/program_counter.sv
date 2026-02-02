module program_counter #(
    parameter XLEN = 32
)(
    input clk,
    
    input instr_comp,
    output [XLEN-1:0] inc_addr,

    output reg [XLEN-1:0] curr_addr,
    
    input jmp_enable,
    input [XLEN-1:0] jmp_offset,

    output [XLEN-1:0] next_addr
);

    // Incremented address calculation
    assign inc_addr = curr_addr + (instr_comp ? 2 : 4);

    // Next address logic
    assign next_addr = jmp_enable ? (curr_addr + jmp_offset) : inc_addr;
    // PC register update
    always @(posedge clk) begin
        curr_addr <= next_addr;
    end
endmodule
