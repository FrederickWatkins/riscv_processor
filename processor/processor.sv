module processor (
    input clk
);
    wire [31:0] imm;

    // Register control
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;

    // ALU control
    wire [2:0] funct3;
    wire [6:0] funct7;

    control_unit cu (
        .imm(imm),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7)
    );

    alu alu_0 (
        .funct3(funct3),
        .invert_op2(funct7[6])
    );

endmodule