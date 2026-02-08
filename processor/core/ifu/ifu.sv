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

    logic compressed;

    assign instr_bus.SEL = 4'b1111; // 32 bits

    assign instr_bus.WE = 0; // Never used for writing
    assign instr_bus.DAT_W = 0;

    always @(*) begin
        next_state = curr_state;
        stalled = 0;
        instr_out = instr_decomp;
        instr_bus.STB = 1;
        instr_bus.CYC = 1;
        if(!instr_bus.ACK) begin
            stalled = 1;
            instr_out = 'h4;
        end
        case(curr_state)
        RUNNING: begin
            instr_bus.STB = 1;
            instr_bus.CYC = 1;
            if(opcode == BRANCH | opcode == JALR | opcode == JAL) begin
                stalled = 1;
                next_state = JUMP;
                instr_bus.STB = 0;
                instr_bus.CYC = 0;
            end
        end
        JUMP: begin
            instr_bus.STB = 0;
            instr_bus.CYC = 0;
            stalled = 1;
            if(jack) begin
                stalled = 0;
                instr_bus.STB = 1;
                instr_bus.CYC = 1;
                next_state = RUNNING;
            end
        end
        endcase
    end

    always @(posedge clk) begin
        curr_state <= next_state;
    end

    pc #(
        .XLEN(XLEN)
    ) pc (
        .clk,

        .stall(stall),
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
