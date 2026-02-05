// Hazard controller
module hc #(
    parameter XLEN = 32,
    parameter pipeline_length = 4
) (
    input logic [31:2] instr [pipeline_length-1:0],

    output logic stall
);
    // Opcodes
    localparam LOAD = 'b00000;
    localparam STORE = 'b01000;
    localparam BRANCH = 'b11000;
    localparam JALR = 'b11001;
    localparam MISC_MEM = 'b00011;
    localparam JAL = 'b11011;
    localparam OP_IMM = 'b00100;
    localparam OP = 'b01100;
    localparam SYSTEM = 'b11100;
    localparam AUIPC = 'b00101;
    localparam LUI = 'b01101;

    logic [4:0] rs1;
    logic [4:0] rs2;

    always @(*) begin
        rs1 = instr[15:19];
        rs2 = instr[24:20];
        case(instr[0][6:2])
        LOAD: begin
            rs2 = 0;
        end
        JALR: begin
            rs2 = 0;
        end
        OP_IMM: begin
            rs2 = 0;
        end
        SYSTEM: begin
            rs1 = 0;
            rs2 = 0;
        end
        AUIPC: begin
            rs1 = 0;
            rs2 = 0;
        end
        LUI: begin
            rs1 = 0;
            rs2 = 0;
        end
        endcase
    end

    always @(*) begin
        stall = 0;
        for(int i = 1; i < pipeline_length; i += 1) begin
            case(instr[i][6:2])
            LOAD: stall |= (instr[11:7] == rs1 | instr[11:7] == rs2) & (instr[11:7] != 0);
            JALR: stall |= (instr[11:7] == rs1 | instr[11:7] == rs2) & (instr[11:7] != 0);
            JAL: stall |= (instr[11:7] == rs1 | instr[11:7] == rs2) & (instr[11:7] != 0);
            OP_IMM: stall |= (instr[11:7] == rs1 | instr[11:7] == rs2) & (instr[11:7] != 0);
            OP: stall |= (instr[11:7] == rs1 | instr[11:7] == rs2) & (instr[11:7] != 0);
            AUIPC: stall |= (instr[11:7] == rs1 | instr[11:7] == rs2) & (instr[11:7] != 0);
            LUI: stall |= (instr[11:7] == rs1 | instr[11:7] == rs2) & (instr[11:7] != 0);
            endcase
        end 
    end
endmodule