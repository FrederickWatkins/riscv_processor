// Instruction decompressor
module decomp (
    input logic [31:0] instr_in,
    output logic compressed,
    output logic [31:2] instr_out
);
    always @(*) begin
        compressed = 0;
        if(instr_in[1:0] == 'b11) instr_out = instr_in[31:2];
        else begin
            // TODO decompression logic
            compressed = 1;
            instr_out = 'h00000013; // NOP
        end
    end
endmodule
