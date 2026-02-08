// RV32IC core
/* verilator lint_off UNOPTFLAT */
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


    logic [31:2] instr [pipeline_length-1:0] /* verilator split_var */;
    logic [XLEN-1:0] curr_pc [pipeline_length-1:0];
    logic [XLEN-1:0] inc_pc [pipeline_length-1:0];
    logic [XLEN-1:0] rs1_data[pipeline_length-1:2], rs2_data[pipeline_length-1:2], ieu_result[pipeline_length-1:2], lsu_data;
    logic stalled[pipeline_length-1:0];
    logic stall[pipeline_length-1:0];
    logic je, jack;

    generate
        for (genvar i = 0; i < pipeline_length; i++) begin : gen_stall
            if (i == pipeline_length - 1) begin: gen_final_stall
                // Final stage only depends on its own stalled signal
                assign stall[i] = stalled[i];
            end else begin: gen_prop_stall
                // Higher stages propagate stalls down to lower stages
                assign stall[i] = stalled[i] | stall[i+1];
            end
        end
    endgenerate

    generate
        for (genvar i = 1; i < pipeline_length; i++) begin : gen_pipe_regs
            always @(posedge clk) begin
                // Standard propagation
                if (!stall[i]) begin
                    instr[i]   <= instr[i-1];
                    inc_pc[i]  <= inc_pc[i-1];
                    curr_pc[i] <= curr_pc[i-1];
                end
                
                // Injection of NOP on a bubble
                if (stall[i-1] && !stall[i]) begin
                    instr[i] <= NOP;
                end
            end
        end
    endgenerate

    always @(posedge clk) begin
        if(!stall[3]) begin
            ieu_result[3] <= ieu_result[2];
            rs1_data[3] <= rs1_data[2];
            rs2_data[3] <= rs2_data[2];
        end
    end

    hc #(
        .pipeline_length(pipeline_length)
    ) hc (
        .instr(instr[3:0]),
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
        .inc_pc(inc_pc[3]),
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
        // Outputs
        .stalled(stalled[3]),
        .data(lsu_data)
    );
endmodule
/* verilator lint_on UNOPTFLAT */
