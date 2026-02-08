// Instruction fetch unit
module ifu #(
    parameter XLEN = 32
) (
    input logic clk,

    wishbone.MASTER instr_bus,

    input logic stall,
    input logic jack,
    input logic je,
    input logic [XLEN-1:0] ja,

    output logic stalled,
    output logic [31:2] instr_out,
    output logic [XLEN-1:0] curr_pc,
    output logic [XLEN-1:0] inc_pc
);
    typedef enum logic {
        RUNNING, // Running normally (still stall if pipeline stalls)
        JUMP // Waiting for acknowledgement of earlier jump instruction
    } state;

    state curr_state;
    state next_state;

    logic [31:2] instr_decomp;

    logic [4:0] opcode = instr_out[6:2];

    logic compressed, pc_stall, instr_escaped;

    assign instr_bus.SEL = 4'b1111; // 32 bits

    assign instr_bus.WE = 0; // Never used for writing
    assign instr_bus.DAT_W = 0;

    always @(*) begin
        next_state = curr_state;
        stalled = 0;
        instr_out = instr_decomp;
        instr_bus.STB = 1;
        instr_bus.CYC = 1;
        pc_stall = stall;
        if(!instr_bus.ACK) begin
            pc_stall = 1;
            instr_out = 'h4;
        end
        case(curr_state)
        RUNNING: begin
            if(opcode == BRANCH | opcode == JALR | opcode == JAL) begin
                pc_stall = 1;
                next_state = JUMP;
            end
        end
        JUMP: begin
            pc_stall = 1;
            if(instr_escaped) begin
                instr_out = 'h4;
            end
            if(jack) begin
                pc_stall = 0;
                next_state = RUNNING;
            end
        end
        endcase
    end

    always @(posedge clk) begin
        curr_state <= next_state;
        if(curr_state==RUNNING && next_state==JUMP) instr_escaped <= 0;
        if(!stall) instr_escaped <= 1;
    end

    pc #(
        .XLEN(XLEN)
    ) pc (
        .clk,

        .stall(pc_stall),
        .compressed,
        .je,
        .ja,

        .curr_pc,
        .inc_pc,
        .next_pc(instr_bus.ADR)
    );

    decomp decomp (
        .instr_in(instr_bus.DAT_R),

        .compressed,
        .instr_out(instr_decomp)
    );
endmodule
