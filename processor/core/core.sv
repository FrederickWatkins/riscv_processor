// RV32IC core

module core #(
    parameter XLEN = 32
) (
    input logic clk,
    // Instruction port
    wishbone.MASTER instr_bus
    // Data port
    wishbone.MASTER data_bus
);
    localparam pipeline_length = 4;

    localparam NOP = 30'h4;

    logic [31:2] instr [pipeline_length-1:0];
    logic [XLEN-1:0] curr_pc [2:0];
    logic [XLEN-1:0] inc_pc [2:0];
    logic [XLEN-1:0] writeback_data;
    logic stalled[pipeline_length-2:0]
    logic stall[pipeline_length-1:0];

    always @(*) begin
        for (int i = pipeline_length - 1; i > 0; i -= 1) begin
            stall[i - 1] = stalled[i - 1] | stall[i];
        end
    end

    always @(posedge clk) begin
        for (int i = 0; i < pipeline_length - 1; i += 1) begin
            if(!stall[i]) begin
                instr[i + 1] <= instr[i];
                if(i == 0) instr[i] = NOP;
                else if(stall[i - 1]) instr[i] = NOP;
            end
        end
        curr_pc[2] <= curr_pc[1];
        curr_pc[1] <= curr_pc[0];
        inc_pc[2] <= inc_pc[2];
        inc_pc[1] <= inc_pc[0];
    end

    hc #(
        .XLEN(XLEN),
        .pipeline_length(pipeline_length)
    ) hc (
        .instr,
        .stall(stalled[1])
    );

    ifu #(
        .XLEN(XLEN)
    ) ifu (
        .clk,
        // Inputs
        .stall(stall[0]),
        .je,
        .ja,
        .instr_bus,
        // Ouputs
        .stalled(stalled[0]),
        .instr_out(instr[0]),
        .curr_pc,
        .inc_pc,
        .next_pc(instr_addr)
    );

    ieu #(
        .XLEN(XLEN)
    ) ieu (
        .clk,
        // Inputs
        .stall_decode(stall[1]),
        .decode_instr(instr[1]),
        .curr_pc(curr_pc[2]),
        .inc_pc(inc_pc[2]),
        .writeback_instr(instr[3]),
        .writeback_data,
        // Outputs
        .je,
        .ja,
    )

    lsu #(
        .XLEN(XLEN)
    ) lsu (
        .clk,
        // Interfaces
        wishbone.MASTER data_bus,
        // Inputs
        .instr(instr[3]),
        .ieu_result,
        .ieu_rs2,
        .stall(stall[3]),
        // Outputs
        .stalled(stalled[2]),
        .writeback_data
    )
endmodule
