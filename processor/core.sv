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
    // Pipeline delays
    localparam fetch_decode_delay = 0;
    localparam decode_execute_delay = 0; // From input of decode to input of execute
    localparam execute_memory_delay = 0; // From input of execute to input of memory
    localparam memory_writeback_delay = 1; // From input of memory to input of writeback
    // Total delays
    localparam fetch_execute_delay = fetch_decode_delay + decode_execute_delay;
    localparam fetch_writeback_delay = fetch_decode_delay + decode_execute_delay + execute_memory_delay + memory_writeback_delay;
    localparam decode_memory_delay = decode_execute_delay + execute_memory_delay;
    localparam decode_writeback_delay = decode_execute_delay + execute_memory_delay + memory_writeback_delay;

    // Fetch stage control signals
    typedef struct packed {
        logic stall;
        logic [XLEN-1:0] jump_addr;
        logic jump_enable;
    } fetch_ctrl_signals;
    // Execute stage control signals
    typedef struct packed {
        logic [4:0] rs1_addr;
        logic [4:0] rs2_addr;
        execute_function_e function_select;
        logic [2:0] funct3;
        logic [6:0] funct7;
    } execute_ctrl_signals;
    // Memory stage control signals
    typedef struct packed {
        logic mm_re;
        logic mm_we;
    } memory_ctrl_signals;
    // Writeback stage control signals
    typedef struct packed {
        logic [4:0] rd_addr;
        logic rd_we;
        writeback_function_e wb_select;
    } writeback_ctrl_signals;

    fetch_ctrl_signals fetch_ctrl;
    execute_ctrl_signals execute_ctrl [decode_execute_delay:0];
    memory_ctrl_signals memory_ctrl [decode_memory_delay:0];
    writeback_ctrl_signals writeback_ctrl [decode_writeback_delay:0];

    // --- Data flow ---
    // Fetch unit -> decode unit
    logic [31:0] fetched_instr;
    // Decode unit -> execute unit
    logic [31:0] imm;
    // Execute unit -> memory unit
    logic [XLEN-1:0] execute_result;
    // Memory unit -> writeback unit
    logic [XLEN-1:0] mem_result;
    // Fetch unit -> writeback unit
    logic [XLEN-1:0] curr_pc[fetch_writeback_delay];

    always @(posedge clk) begin
        for(integer i = 0; i < decode_execute_delay; i = i + 1) execute_ctrl[i+1] <= execute_ctrl[i];
        for(integer i = 0; i < decode_memory_delay; i = i + 1) memory_ctrl[i+1] <= memory_ctrl[i];
        for(integer i = 0; i < decode_writeback_delay; i = i + 1) writeback_ctrl[i+1] <= writeback_ctrl[i];
        for(integer i = 0; i < fetch_writeback_delay; i = i + 1) curr_pc[i+1] <= curr_pc[i];
    end

    hazard_unit #(
        .XLEN(XLEN)
        .pipeline_length(decode_writeback_delay)
    ) hazard_unit_0 (
        // Data inputs
        .rs1_addr(instr_in[19:15]),
        .rs2_addr(instr_in[24:20]),
        .writeback_ctrl(writeback_ctrl),

        // Control signal outputs
        .stall(stall)
    )

    fetch_unit #(
        .XLEN(XLEN)
    ) fetch_unit_0 (
        .clk(clk),
        // Control signal inputs
        .jump_addr(fetch_ctrl.jump_addr),
        .jump_enable(fetch_ctrl.jump_enable),
        .stall(fetch_ctrl.stall),
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
        .function_select(execute_ctrl[0].function_select)
        .rs1_addr(execute_ctrl[0].rs1_addr),
        .rs2_addr(execute_ctrl[0].rs2_addr),
        .funct3(execute_ctrl[0].funct3),
        .funct7(execute_ctrl[0].funct7),
        // Memory stage control signals
        .mm_re(memory_ctrl[0].mm_re),
        .mm_we(memory_ctrl[0].mm_we),
        // Writeback stage control signals
        .rd_addr(writeback_ctrl[0].rd_addr),
        .rd_we(writeback_ctrl[0].rd_we),
        .wb_select(writeback_ctrl[0].wb_select)
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
        // Control signal inputs
        .mm_re(mm_re),
        .mm_we(mm_we),
        // Data inputs
        .execute_result(execute_result),
        .read_data(data_in),
        // Data outputs
        .write_data(data_out),
        .data_we(data_we),
        .data_addr(data_addr),
        .result(mem_result)
    );

    writeback_unit #(
        .XLEN(XLEN)
    ) writeback_unit_0 (
        // Control inputs
        .wb_select(wb_select_d1),
        // Data inputs
        .mem_result(mem_result),
        .curr_instr(curr_instr_d1),
        // Data outputs
        .rd_data(rd_data)
    );
endmodule