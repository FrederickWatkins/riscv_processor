// Integer execution unit
module ieu #(
    parameter XLEN = 32
) (
    input logic clk,
    // Decode stage inputs
    input logic [31:2] instr,
    // Execute stage inputs
    input logic stall,
    input logic [XLEN-1:0] curr_pc, // Current program counter
    input logic [XLEN-1:0] rs1_data,
    input logic [XLEN-1:0] rs2_data,

    output logic [XLEN-1:0] result
);
    logic [XLEN-1:0] imm [1:0], operand_1, operand_2;
    logic [2:0] funct3 [1:0];
    logic [6:0] funct7 [1:0];
    logic op1_pc [1:0], op2_imm [1:0];

    assign operand_1 = op1_pc[1] ? curr_pc : rs1_data;
    assign operand_2 = op2_imm[1] ? imm[1] : rs2_data;

    always @(posedge clk) begin
        if(!stall) begin
            imm[1] <= imm[0];
            funct3[1] <= funct3[0];
            funct7[1] <= funct7[0];
            op1_pc[1] <= op1_pc[0];
            op2_imm[1] <= op2_imm[0];
        end
    end

    idu #(
        .XLEN(XLEN)
    ) idu (
        .instr,

        .imm(imm[0]),
        .funct3(funct3[0]),
        .funct7(funct7[0]),
        .op1_pc(op1_pc[0]),
        .op2_imm(op2_imm[0])
    );

    alu #(
        .XLEN(XLEN)
    ) alu (
        .funct3(funct3[1]),
        .funct7(funct7[1]),
        
        .operand_1,
        .operand_2,

        .result
    );
endmodule
