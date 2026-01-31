module control_unit (
    input [31:0] instr_in,

    output logic [31:0] imm,

    // Register control
    output logic rd_we,
    output [4:0] rd,
    output [4:0] rs1,
    output [4:0] rs2,

    // ALU control
    output [2:0] funct3,
    output logic [6:0] funct7
);
    // Opcodes
    localparam LOAD = 'b00000;
    localparam STORE = 'b01000;
    localparam BRANCH = 'b11000;
    localparam JALR = 'b11001;
    localparam MISC_MEM = 'b00011;
    localparam JAL = 'b01111;
    localparam OP_IMM = 'b00100;
    localparam OP = 'b01100;
    localparam SYSTEM = 'b11100;
    localparam AUIPC = 'b00101;
    localparam LUI = 'b01101;

    wire [4:0] opcode = instruction[6:2];

    // Instruction formats
    localparam R_TYPE = 'b000001;
    localparam I_TYPE = 'b000010;
    localparam S_TYPE = 'b000100;
    localparam B_TYPE = 'b001000;
    localparam U_TYPE = 'b010000;
    localparam J_TYPE = 'b100000;

    logic [5:0] instr_fmt;

    wire [1:0] instr_comp = instr_in[1:0];
    wire [31:0] instruction = instr_comp=='b11?instr_in:exp_instruction;
    
    wire [31:0] exp_instruction;
    expander expander_0 (
        .comp_instr(instr_in[15:0]),
        .exp_instr(exp_instruction)
    );

    assign rd = instruction[11:7];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];

    assign funct3 = instruction[14:12];

    always @(*) begin
        case(opcode)
        LOAD: begin
            instr_fmt = I_TYPE;
        end
        STORE: begin
            instr_fmt = S_TYPE;
        end
        BRANCH: begin
            instr_fmt = B_TYPE;
        end
        JALR: begin
            instr_fmt = I_TYPE;
        end
        MISC_MEM: instr_fmt = R_TYPE; // Do nothing, no cache and in-order
        JAL: begin
            instr_fmt = J_TYPE;
        end
        OP_IMM: begin
            instr_fmt = I_TYPE;
        end
        OP: begin
            instr_fmt = R_TYPE;
        end
        SYSTEM: instr_fmt = I_TYPE; // Do nothing, no breakpoint support
        AUIPC: begin
            instr_fmt = U_TYPE;
        end
        LUI: begin
            instr_fmt = U_TYPE;
        end
        default: begin
            $stop; // Unsupported op code
            instr_fmt = 'z;
        end
        endcase
    end

    always @(*)
    begin
        rd_we = 0;
        funct7 = 0;
        imm = 'z;
        case(instr_fmt)
        R_TYPE: begin
            rd_we = 1;
            funct7 = instruction[31:25];
        end
        I_TYPE: begin
            rd_we = 1;
            imm = {21{instruction[31]}, instruction[30:20]};
            // Special shift case
            if(opcode == OP_IMM & (funct3 == 'b101 | funct3 == 'b001)) begin
                funct7 = instruction[31:25];
                imm[11:0] = instruction[24:20];
            end
        end
        S_TYPE: begin
            imm = {21{instruction[31]}, instruction[30:25], instruction[11:7]};
        end
        B_TYPE: begin
            imm = {20{instruction[31]}, instruction[7], instruction[30:25], instruction[11:8], 'b0};
        end
        U_TYPE: begin
            rd_we = 1;
            imm = {instruction[31:12], 12{'b0}};
        end
        J_TYPE: begin
            rd_we = 1;
            imm = {12{instruction[31]}, instruction[19:12], instruction[20], instruction[30:21], 'b0}
        end
        endcase
    end

endmodule