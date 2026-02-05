// Integer execution unit
module ieu #(
    parameter XLEN = 32,
    wb_delay = 1
) (
    input logic clk,
    input logic stall, // Stall for this cycle
    input logic [31:2] instr,
    input logic [XLEN-1:0] curr_pc, // Current program counter
    input logic [XLEN-1:0] inc_pc, // Incremented program counter

    input logic [XLEN-1:0] rd_data,

    // Signals to fetch unit
    output logic stalled,
    output logic je, // Jump enable
    output logic [XLEN-1:0] ja,
    // Signals to MMU
    output logic [2:0] funct3,
    output logic [XLEN-1:0] result,
    output logic [XLEN-1:0] reg_out, // Register bypass
    output logic mm_we, // Write enable
    output logic mm_re // We want the data we sent out back
);
    logic rd_we[wb_delay:0], op1_pc, op2_imm, jump, branch, idu_rd_we, idu_mm_we;
    logic [4:0] rs1_addr, rs2_addr, rd_addr[wb_delay:0], idu_rd;
    logic [XLEN-1:0] imm, rs1_data, rs2_data, operand_1, operand_2, alu_res;
    logic [2:0] alu_funct3;
    logic [6:0] funct7;

    assign operand_1 = op1_pc?curr_pc:rs1_data;
    assign operand_2 = op2_imm?imm:rs2_data;
    assign reg_out = rs2_data;
    assign result = jump?inc_pc:alu_res;
    assign ja = alu_res;
    assign mm_we = stalled?0:idu_mm_we;

    // Return data delay line
    always @(posedge clk) begin
        for(integer i = 0; i < wb_delay & !stall; i = i + 1) begin
            rd_we[i+1] <= rd_we[i];
            rd_addr[i+1] <= rd_addr[i];
        end
        if(stall) begin
            rd_we[1] <= 0;
            rd_addr[1] <= 0;
        end
    end

    // RAW hazard
    always @(*) begin
        stalled = stall;
        rd_addr[0] = idu_rd;
        rd_we[0] = idu_rd_we;
        for(integer i = 1; i <= wb_delay; i = i + 1) begin
            if((rd_addr[i] == rs1_addr | rd_addr[i] == rs2_addr) & rd_addr[i] != 0 & rd_we[i] == 1) begin
                stalled = 1;
                rd_addr[0] = 0;
                rd_we[0] = 0;
            end
        end
    end

    idu #(
        .XLEN(XLEN)
    ) idu (
        .instr_in(instr),
        .imm,
        
        .rd_we(idu_rd_we),
        .rd(idu_rd),
        .rs1(rs1_addr),
        .rs2(rs2_addr),

        .alu_funct3,
        .funct3,
        .funct7,
        .op1_pc,
        .op2_imm,

        .jump,
        .branch,

        .mm_we(idu_mm_we),
        .mm_re
    );

    irf #(
        .XLEN(XLEN)
    ) irf (
        .clk,
        .rs1_addr,
        .rs1_data,
        .rs2_addr,
        .rs2_data,
        .rd_we(rd_we[1]),
        .rd_addr(rd_addr[1]),
        .rd_data
    );

    alu #(
        .XLEN(XLEN)
    ) alu (
        .funct3(alu_funct3),
        .funct7,
        .operand_1,
        .operand_2,

        .result(alu_res)
    );

    jbu #(
        .XLEN(XLEN)
    ) jbu (
        .jump,
        .branch,
        .funct3,
        

        .rs1_data,
        .rs2_data,

        .je
    );
endmodule
