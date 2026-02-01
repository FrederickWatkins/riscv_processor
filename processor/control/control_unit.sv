module control_unit #(
    parameter XLEN = 32
)(
    input [31:0] instr_in,

    output logic [XLEN-1:0] imm,

    // Register control
    output logic rd_we,
    output [4:0] rd,
    output [4:0] rs1,
    output [4:0] rs2,

    // Bus control
    output bus_1_enum::inputs bus_1_sel,
    output bus_2_enum::inputs bus_2_sel,
    output bus_3_enum::inputs bus_3_sel,

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
    typedef enum { 
        R_TYPE,
        I_TYPE,
        S_TYPE,
        B_TYPE,
        U_TYPE,
        J_TYPE
    } instr_type;

    instr_type instr_fmt;

    wire [1:0] instr_comp = instr_in[1:0];
    wire [31:0] instruction = (instr_comp=='b11)?instr_in:exp_instruction;
    
    wire [31:0] exp_instruction;
    expander expander_0 (
        .comp_instruction(instr_in[15:0]),
        .exp_instruction(exp_instruction)
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
            //$stop; // Unsupported op code
            instr_fmt = instr_type'('x);
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
            imm = {{(XLEN-11){instruction[31]}}, instruction[30:20]};
            // Special shift case
            if(opcode == OP_IMM & (funct3 == 'b101 | funct3 == 'b001)) begin
                funct7 = XLEN==32?instruction[31:25]:{instruction[31:26], 1'b0};
                imm = XLEN==32?{{(XLEN-5){1'b0}}, instruction[24:20]}:{{(XLEN-6){1'b0}}, instruction[25:20]};
            end
        end
        S_TYPE: begin
            imm = {{(XLEN-11){instruction[31]}}, instruction[30:25], instruction[11:7]};
        end
        B_TYPE: begin
            imm = {{(XLEN-12){instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        end
        U_TYPE: begin
            rd_we = 1;
            imm = {{(XLEN-31){instruction[31]}}, instruction[30:12], {12{1'b0}}};
        end
        J_TYPE: begin
            rd_we = 1;
            imm = {{(XLEN-20){instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        end
        endcase
    end

endmodule