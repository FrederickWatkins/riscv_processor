// Hazard controller
module hc #(
    parameter pipeline_length = 4
) (
    input logic [31:2] instr [pipeline_length-1:0],

    output logic stall
);
    logic [4:0] rs1;
    logic [4:0] rs2;

    always @(*) begin
        rs1 = instr[0][19:15];
        rs2 = instr[0][24:20];
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
        default: ;
        endcase
    end

    always @(*) begin
        stall = 0;
        for(int i = 1; i < pipeline_length; i += 1) begin
            case(instr[i][6:2])
            LOAD: stall |= (instr[i][11:7] == rs1 | instr[i][11:7] == rs2) & (instr[i][11:7] != 0);
            JALR: stall |= (instr[i][11:7] == rs1 | instr[i][11:7] == rs2) & (instr[i][11:7] != 0);
            JAL: stall |= (instr[i][11:7] == rs1 | instr[i][11:7] == rs2) & (instr[i][11:7] != 0);
            OP_IMM: stall |= (instr[i][11:7] == rs1 | instr[i][11:7] == rs2) & (instr[i][11:7] != 0);
            OP: stall |= (instr[i][11:7] == rs1 | instr[i][11:7] == rs2) & (instr[i][11:7] != 0);
            AUIPC: stall |= (instr[i][11:7] == rs1 | instr[i][11:7] == rs2) & (instr[i][11:7] != 0);
            LUI: stall |= (instr[i][11:7] == rs1 | instr[i][11:7] == rs2) & (instr[i][11:7] != 0);
            default: ;
            endcase
        end 
    end
endmodule
