// Arithmetic logic unit
module alu #(
    parameter XLEN = 32
)(
    // Control
    input [2:0] funct3,
    /* verilator lint_off UNUSEDSIGNAL */
    input [6:0] funct7,
    /* verilator lint_on UNUSEDSIGNAL */

    // Operands
    input [XLEN-1:0] operand_1,
    input [XLEN-1:0] operand_2,

    output logic [XLEN-1:0] result
);
    // Funct3 values
    localparam ADD = 'b000; // Add op1 to op2 (if funct7[5] subtract)
    localparam SL = 'b001; // Left shift
    localparam SLT = 'b010; // Set less than (op1 < op2)
    localparam SLTU = 'b011; // Set less than unsigned
    localparam XOR = 'b100; // Bitwise XOR
    localparam SR = 'b101; // Right shift (if funct7[5] arithmetic right shift)
    localparam OR = 'b110; // Bitwise OR
    localparam AND = 'b111; // Bitwise AND

    localparam shamt_len = XLEN == 32 ? 5 : 6;

    always @(*) begin
        case(funct3)
        ADD: result = funct7[5] ? operand_1 - operand_2 : operand_1 + operand_2;
        SL: result = operand_1 << operand_2[shamt_len-1:0];
        SLT: result = {{(XLEN-1){1'b0}}, $signed(operand_1) < $signed(operand_2)};
        SLTU: result = {{(XLEN-1){1'b0}}, operand_1 < operand_2};
        XOR: result = operand_1 ^ operand_2;
        SR: result = funct7[5]?$unsigned($signed(operand_1)>>>operand_2[shamt_len-1:0]):operand_1>>operand_2[shamt_len-1:0];
        OR: result = operand_1 | operand_2;
        AND: result = operand_1 & operand_2;
        endcase
    end

endmodule
