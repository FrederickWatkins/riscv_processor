// Integer decode unit
module idu #(
    parameter XLEN = 32
)(
    input logic [31:2] instr,

    output logic [XLEN-1:0] imm,

    // ALU control
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic op1_pc,
    output logic op2_imm
);
    logic [4:0] opcode = instr[6:2];

    always @(*) begin
        op1_pc = 0;
        op2_imm = 0;
        funct3 = instr[14:12];
        funct7 = 0;
        imm = 'x;
        case(opcode)
        LOAD: begin
            op2_imm = 1;
            funct3 = 'b000; // Use alu to add addresses
            imm = {{(XLEN-11){instr[31]}}, instr[30:20]};
        end
        STORE: begin
            op2_imm = 1;
            funct3 = 'b000; // Use alu to add addresses
            imm = {{(XLEN-11){instr[31]}}, instr[30:25], instr[11:7]};
        end
        BRANCH: begin
            op1_pc = 1;
            op2_imm = 1;
            funct3 = 'b000; // Use alu to add addresses
            imm = {{(XLEN-12){instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        end
        JALR: begin
            op2_imm = 1;
            funct3 = 'b000; // Use alu to add addresses
            imm = {{(XLEN-11){instr[31]}}, instr[30:20]};
        end
        MISC_MEM: ; // Do nothing, no cache and in-order
        JAL: begin
            op1_pc = 1;
            op2_imm = 1;
            funct3 = 'b000; // Use alu to add addresses
            imm = {{(XLEN-20){instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        end
        OP_IMM: begin
            op2_imm = 1;
            imm = {{(XLEN-11){instr[31]}}, instr[30:20]};
            // Special shift case
            if(funct3 == 'b101 | funct3 == 'b001) begin
                funct7 = XLEN==32?instr[31:25]:{instr[31:26], 1'b0};
                imm = XLEN==32?{{(XLEN-5){1'b0}}, instr[24:20]}:{{(XLEN-6){1'b0}}, instr[25:20]};
            end
        end
        OP: begin
            funct7 = instr[31:25];
        end
        SYSTEM: ; // Do nothing, no breakpoint support
        AUIPC: begin
            op1_pc = 1;
            op2_imm = 1;
            funct3 = 'b000; // Use alu to add addresses
            imm = {{(XLEN-31){instr[31]}}, instr[30:12], {12{1'b0}}};
        end
        LUI: begin
            op2_imm = 1;
            funct3 = 'b000; // Use alu to add addresses
            imm = {{(XLEN-31){instr[31]}}, instr[30:12], {12{1'b0}}};
        end
        default: ;
        endcase
    end
endmodule
