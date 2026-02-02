module processor (
    input clk,

    output [XLEN-1:0] instr_addr,
    input [31:0] instr_in,

    output data_we,
    output [XLEN-1:0] data_addr,
    output [XLEN-1:0] data_out,
    input [XLEN-1:0] data_in
);
    localparam XLEN = 32;

    wire [XLEN-1:0] imm;

    // Register control
    wire rd_we;
    wire [4:0] rd_addr;
    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;
    wire [XLEN-1:0] rs1_data;
    wire [XLEN-1:0] rs2_data;

    // Bus control
    wire bus_1_enum::inputs bus_1_sel;
    wire bus_2_enum::inputs bus_2_sel;
    wire bus_3_enum::inputs bus_3_sel;

    // Bus 1
    logic [XLEN-1:0] bus_1_data;
    always @(*) begin
        unique case(bus_1_sel)
        bus_1_enum::rs1: bus_1_data = rs1_data;
        endcase
    end

    // Bus 2
    logic [XLEN-1:0] bus_2_data;
    always @(*) begin
        unique case(bus_2_sel)
        bus_2_enum::rs2: bus_2_data = rs2_data;
        bus_2_enum::imm: bus_2_data = imm;
        endcase
    end
    assign data_out = rs2_data;

    // Bus 3
    logic [XLEN-1:0] bus_3_data;
    always @(*) begin
        unique case(bus_3_sel)
        bus_3_enum::alu: bus_3_data = alu_result;
        bus_3_enum::mm: bus_3_data = data_in;
        bus_3_enum::pc: bus_3_data = inc_addr;
        endcase
    end
    assign data_addr = bus_3_data;

    // ALU control
    wire [2:0] funct3;
    wire [6:0] funct7;

    // PC control
    wire jump_enable;
    wire instr_comp;
    wire [XLEN-1:0] inc_addr;

    control_unit #(
        .XLEN(XLEN)
    ) cu (
        .instr_in(instr_in),
        .imm(imm),
        .rd_we(rd_we),
        .rd(rd_addr),
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .bus_1_sel(bus_1_sel),
        .bus_2_sel(bus_2_sel),
        .bus_3_sel(bus_3_sel),
        .funct3(funct3),
        .funct7(funct7),
        .instr_comp(instr_comp),
        .mm_we(data_we)
    );

    wire [XLEN-1:0] alu_result;
    alu alu_0 (
        .operand_1(bus_1_data),
        .operand_2(bus_2_data),
        .funct3(funct3),
        .invert(funct7[6]),
        .result(alu_result)
    );

    register_file #(
        .addr_width(5),
        .data_width(XLEN)
    ) rf (
        .clk(clk),
        .write_enable(rd_we),
        .rs1_addr(rs1_addr),
        .rs1_data(rs1_data),
        .rs2_addr(rs2_addr),
        .rs2_data(rs2_data),
        .rd_addr(rd_addr),
        .rd_data(bus_3_data)
    );

    program_counter #(
        .XLEN(XLEN)
    ) pc (
        .clk(clk),
        .instr_comp(instr_comp),
        .inc_addr(inc_addr),
        .jmp_enable(jump_enable),
        .jmp_offset(bus_3_data),
        .next_addr(instr_addr)
    );

endmodule
