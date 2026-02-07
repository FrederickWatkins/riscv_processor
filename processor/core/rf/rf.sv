// Register file
module rf #(
    parameter XLEN = 32
) (
    input logic clk,
    // Inputs
    input logic [31:2] rs_instr,
    input logic [31:2] rd_instr,
    input logic [XLEN-1:0] ieu_result,
    input logic [XLEN-1:0] lsu_data,
    input logic [XLEN-1:0] inc_pc,
    // Outputs
    output logic [XLEN-1:0] rs1_data,
    output logic [XLEN-1:0] rs2_data
);
    logic rd_we;

    logic [4:0] rd_opcode = rd_instr[6:2];
    logic [XLEN-1:0] rd_data;

    logic [4:0] rs1_addr = rs_instr[19:15];
    logic [4:0] rs2_addr = rs_instr[24:20];
    logic [4:0] rd_addr = rd_instr[11:7];

    always @(*) begin
        rd_we = 0;
        rd_data = 'x;
        case(rd_opcode)
        LOAD: begin
            rd_we = 1;
            rd_data = lsu_data;
        end
        JALR: begin
            rd_we = 1;
            rd_data = inc_pc;
        end
        JAL: begin
            rd_we = 1;
            rd_data = inc_pc;
        end
        OP_IMM: begin
            rd_we = 1;
            rd_data = ieu_result;
        end
        OP: begin
            rd_we = 1;
            rd_data = ieu_result;
        end
        AUIPC: begin
            rd_we = 1;
            rd_data = ieu_result;
        end
        LUI: begin
            rd_we = 1;
            rd_data = ieu_result;
        end
        default: ;
        endcase
    end

    sync_sram #(
        .XLEN(XLEN)
    ) irf (
        .clk,

        .rs1_addr,
        .rs2_addr,
        .rd_we,
        .rd_addr,
        .rd_data,

        .rs1_data,
        .rs2_data
    );
endmodule
