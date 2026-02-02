localparam XLEN = 32;

module core (
    input clk,

    output [XLEN-1:0] instr_addr,
    input [31:0] instr_in,

    output data_we,
    output [XLEN-1:0] data_addr,
    output [XLEN-1:0] data_out,
    input [XLEN-1:0] data_in
);

    // --- Control signals ---
    // Global control signals
    logic stall;
    // Fetch stage control signals
    logic [XLEN-1:0] jump_addr;
    logic jump_enable;
    // Execute stage control signals
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    execute_function_e function_select;
    logic [2:0] funct3;
    logic [6:0] funct7;
    // Memory stage control signals
    logic mm_re;
    logic mm_we;
    // Writeback stage control signals
    logic [4:0] rd_addr_d0;
    logic [4:0] rd_addr_d1;
    logic rd_we_d0;
    logic rd_we_d1;

    always @(posedge clk) begin
        rd_addr_d1 <= rd_addr_d0;
        rd_we_d1 <= rd_we_d0;
    end

    // --- Data flow ---
    // Fetch unit -> decode unit
    logic [31:0] fetched_instr;
    // Decode unit -> execute unit
    logic [31:0] imm;
    // Execute unit -> memory unit
    logic [XLEN-1:0] execute_result;
    // Execute unit -> fetch unit


    hazard_unit #(
        .XLEN(XLEN)
    ) hazard_unit_0 (
        .rs1_addr(instr_in[19:15]),
        .rs2_addr(instr_in[24:20])
        .rd_addr(rd_addr_d0),
        .stall(stall)
    )

    fetch_unit #(
        .XLEN(XLEN)
    ) fetch_unit_0 (
        .clk(clk),
        // Control signal inputs
        .jump_addr(jump_addr)
        .jump_enable(jump_enable)
        // Data inputs
        .instr_in(instr_in),
        // Control signal outputs
        .instr_addr(instr_addr),
        // Data outputs
        .fetched_instr(fetched_instr)
    );

    decode_unit #(
        .XLEN(XLEN)
    ) decode_unit_0 (
        // Data inputs
        .instr_in(fetched_instr),
        // Execute stage control signals
        .function_sel(function_sel)
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .funct3(funct3),
        .funct7(funct7),
        // Memory stage control signals
        .mm_re(mm_re),
        .mm_we(mm_we),
        // Writeback stage control signals
        .rd_addr(rd_addr_d0),
        .rd_we(rd_we_d0),
        // Data outputs
        .imm(imm)
    );

    execute_unit #(
        .XLEN(XLEN)
    ) execute_unit_0 (
        // Control inputs
        .function_select(function_select)
        .funct3(funct3),
        .funct7(funct7),
        // Data inputs
        .imm(imm),
        .curr_instr(curr_instr),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        // Control outputs
        .jump_addr(jump_addr)
        .jump_enable(jump_enable)
        // Data outputs
        .result(exexcute_result)
    );

    memory_unit #(
        .XLEN(XLEN)
    ) memory_unit_0 (
        .clk(clk)

        .mm_re(mm_re),
        .mm_we(mm_we),

        .execute_result(execute_result),
        .read_data(data_in),
        .write_data(data_out),

        .data_we(data_we),
        .data_addr(data_addr),

        .result(mem_result)
    );

    writeback_unit #(
        .XLEN(XLEN)
    ) writeback_unit_0 (
        .mem_result(mem_result),

        .rd(rd)
    );
endmodule