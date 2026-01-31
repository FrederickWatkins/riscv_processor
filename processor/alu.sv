module alu (
    // Control
    input [2:0] funct3,
    input invert_op2,

    // Operands
    input [31:0] operand_1,
    input [31:0] operand_2,

    output [31:0] result
);
endmodule