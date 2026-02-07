// Jump and branch unit
module jbu #(
    parameter XLEN = 32
) (
    input logic [31:2] instr,

    input logic [XLEN-1:0] rs1_data,
    input logic [XLEN-1:0] rs2_data,

    output logic jack,
    output logic je
);
    localparam BEQ = 3'b000;
    localparam BNE = 3'b001;
    localparam BLT = 3'b100;
    localparam BGE = 3'b101;
    localparam BLTU = 3'b110;
    localparam BGEU = 3'b111;

    logic [4:0] opcode = instr[6:2];
    logic [2:0] funct3 = instr[14:12];

    always @(*) begin
        jack = 0;
        je = 0;
        case(opcode)
        BRANCH: begin
            jack = 1;
            case(funct3)
            BEQ: je = rs1_data == rs2_data;
            BNE: je = rs1_data != rs2_data;
            BLT: je = $signed(rs1_data) < $signed(rs2_data);
            BGE: je = $signed(rs1_data) >= $signed(rs2_data);
            BLTU: je = rs1_data < rs2_data;
            BGEU: je = rs1_data >= rs2_data;
            default: $warning("Unrecognised branch funct3");
            endcase
        end
        JALR: begin
            jack = 1;
            je = 1;
        end
        JAL: begin
            jack = 1;
            je = 1;
        end
        default: ;
        endcase
    end
endmodule
