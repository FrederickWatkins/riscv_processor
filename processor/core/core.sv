// RV32IC core

module core #(
    parameter XLEN = 32
) (
    input logic clk,
    // Instruction port
    wishbone.MASTER instr_bus,
    // Data port
    wishbone.MASTER data_bus
);
    localparam pipeline_length = 4;

    localparam NOP = 30'h4;

    logic [31:2] instr [pipeline_length-1:0];
    logic [XLEN-1:0] curr_pc [2:0];
    logic [XLEN-1:0] inc_pc [pipeline_length-1:0];
    logic [XLEN-1:0] rs1_data[pipeline_length-1:2], rs2_data[pipeline_length-1:2], ieu_result[pipeline_length-1:2], lsu_data;
    logic stalled[pipeline_length-2:0];
    logic stall[pipeline_length-1:0];
    logic je, jack;

    always @(*) begin
        for (int i = pipeline_length - 1; i > 0; i -= 1) begin
            stall[i - 1] = stalled[i - 1] | stall[i];
        end
    end

    always @(posedge clk) begin
        for (int i = 0; i < pipeline_length - 1; i += 1) begin
            if(!stall[i]) begin
                instr[i + 1] <= instr[i];
                inc_pc[i + 1] <= inc_pc[i];
                if(stall[i - 1]) instr[i] = NOP;
            end
        end
        curr_pc[2] <= curr_pc[1];
        curr_pc[1] <= curr_pc[0];
    end

    hc #(
        .XLEN(XLEN),
        .pipeline_length(pipeline_length)
    ) hc (
        .instr,
        .stall(stalled[1])
    );

    rf #(
        .XLEN(XLEN)
    ) rf (
        .clk,
        // Inputs
        .rs_instr(instr[1]),
        .rd_instr(instr[3]),
        .ieu_result(ieu_result[3]),
        .lsu_data,
        // Outputs
        .rs1_data(rs1_data[2]),
        .rs2_data(rs2_data[2])
    );

    ifu #(
        .XLEN(XLEN)
    ) ifu (
        .clk,
        // Inputs
        .stall(stall[0]),
        .jack,
        .je,
        .ja(ieu_result[2]),
        .instr_bus,
        // Ouputs
        .stalled(stalled[0]),
        .instr_out(instr[0]),
        .curr_pc(curr_pc[0]),
        .inc_pc(inc_pc[0])
    );

    ieu #(
        .XLEN(XLEN)
    ) ieu (
        .clk,
        // Decode stage inputs
        .instr(instr[1]),
        // Execute stage inputs
        .stall(stall[2]),
        .curr_pc(curr_pc[2]),
        .rs1_data(rs1_data[2]),
        .rs2_data(rs2_data[2]),
        // Outputs
        .result(ieu_result[2])
    );

    jbu #(
        .XLEN(XLEN)
    ) jbu (
        // Inputs
        .instr(instr[2]),
        .rs1_data(rs1_data[2]),
        .rs2_data(rs2_data[2]),
        // Outputs
        .jack,
        .je
    );

    lsu #(
        .XLEN(XLEN)
    ) lsu (
        .clk,
        // Interfaces
        .data_bus,
        // Inputs
        .instr(instr[3]),
        .ieu_result(ieu_result[3]),
        .rs2_data(rs2_data[3]),
        .stall(stall[3]),
        // Outputs
        .stalled(stalled[2]),
        .data(lsu_data)
    );
endmodule
