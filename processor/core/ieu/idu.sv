// Integer decode unit
module idu #(
    parameter XLEN = 32
)(
    input logic [31:2] instr_in,

    output logic [XLEN-1:0] imm,

    // Register control
    output logic rd_we,
    output logic [4:0] rd,
    output logic [4:0] rs1,
    output logic [4:0] rs2,

    // ALU control
    output logic [2:0] alu_funct3,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic op1_pc,
    output logic op2_imm,

    // Jump and branch unit control
    output logic jump,
    output logic branch,

    // Main memory control
    output logic mm_we,
    output logic mm_re
);
    // Opcodes
    localparam LOAD = 'b00000; // TODO fix lb and lh
    localparam STORE = 'b01000;// TODO fix sb and sh
    localparam BRANCH = 'b11000;
    localparam JALR = 'b11001;
    localparam MISC_MEM = 'b00011;
    localparam JAL = 'b11011;
    localparam OP_IMM = 'b00100;
    localparam OP = 'b01100;
    localparam SYSTEM = 'b11100;
    localparam AUIPC = 'b00101;
    localparam LUI = 'b01101;

    logic [4:0] opcode = instr_in[6:2];
    assign funct3 = instr_in[14:12];

    // Instruction formats
    typedef enum { 
        R_TYPE,
        I_TYPE,
        S_TYPE,
        B_TYPE,
        U_TYPE,
        J_TYPE
    } instr_type;

    instr_type instr_fmt;

    always @(*) begin
        jump = 0;
        branch = 0;
        op1_pc = 0;
        op2_imm = 0;
        mm_we = 0;
        rd_we = 0;
        mm_re = 0;
        alu_funct3 = funct3;
        case(opcode)
        LOAD: begin
            instr_fmt = I_TYPE;
            op2_imm = 1;
            rd_we = 1;
            mm_re = 1;
            alu_funct3 = 'b000; // Use alu to add addresses
        end
        STORE: begin
            instr_fmt = S_TYPE;
            op2_imm = 1;
            mm_we = 1;
            alu_funct3 = 'b000; // Use alu to add addresses
        end
        BRANCH: begin
            instr_fmt = B_TYPE;
            branch = 1;
            op1_pc = 1;
            op2_imm = 1;
            alu_funct3 = 'b000; // Use alu to add addresses
        end
        JALR: begin
            instr_fmt = I_TYPE;
            jump = 1;
            op2_imm = 1;
            rd_we = 1;
            alu_funct3 = 'b000; // Use alu to add addresses
        end
        MISC_MEM: instr_fmt = R_TYPE; // Do nothing, no cache and in-order
        JAL: begin
            instr_fmt = J_TYPE;
            jump = 1;
            op1_pc = 1;
            op2_imm = 1;
            rd_we = 1;
            alu_funct3 = 'b000; // Use alu to add addresses
        end
        OP_IMM: begin
            instr_fmt = I_TYPE;
            op2_imm = 1;
            rd_we = 1;
        end
        OP: begin
            instr_fmt = R_TYPE;
            rd_we = 1;
        end
        SYSTEM: instr_fmt = I_TYPE; // Do nothing, no breakpoint support
        AUIPC: begin
            instr_fmt = U_TYPE;
            op1_pc = 1;
            op2_imm = 1;
            rd_we = 1;
            alu_funct3 = 'b000; // Use alu to add addresses
        end
        LUI: begin
            instr_fmt = U_TYPE;
            op2_imm = 1;
            rd_we = 1;
            alu_funct3 = 'b000; // Use alu to add addresses
        end
        default: begin
            instr_fmt = instr_type'('x);
        end
        endcase
    end

    always @(*)
    begin
        // Set registers to zero if not used to avoid false hazards
        rd = 0;
        rs1 = 0;
        rs2 = 0;
        funct7 = 0;
        imm = 'x;
        case(instr_fmt)
        R_TYPE: begin
            rd = instr_in[11:7];
            rs1 = instr_in[19:15];
            rs2 = instr_in[24:20];
            funct7 = instr_in[31:25];
        end
        I_TYPE: begin
            rd = instr_in[11:7];
            rs1 = instr_in[19:15];
            imm = {{(XLEN-11){instr_in[31]}}, instr_in[30:20]};
            // Special shift case
            if(opcode == OP_IMM & (funct3 == 'b101 | funct3 == 'b001)) begin
                funct7 = XLEN==32?instr_in[31:25]:{instr_in[31:26], 1'b0};
                imm = XLEN==32?{{(XLEN-5){1'b0}}, instr_in[24:20]}:{{(XLEN-6){1'b0}}, instr_in[25:20]};
            end
        end
        S_TYPE: begin
            rs1 = instr_in[19:15];
            rs2 = instr_in[24:20];
            imm = {{(XLEN-11){instr_in[31]}}, instr_in[30:25], instr_in[11:7]};
        end
        B_TYPE: begin
            rs1 = instr_in[19:15];
            rs2 = instr_in[24:20];
            imm = {{(XLEN-12){instr_in[31]}}, instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
        end
        U_TYPE: begin
            rd = instr_in[11:7];
            imm = {{(XLEN-31){instr_in[31]}}, instr_in[30:12], {12{1'b0}}};
        end
        J_TYPE: begin
            rd = instr_in[11:7];
            imm = {{(XLEN-20){instr_in[31]}}, instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0};
        end
        endcase
    end

endmodule
