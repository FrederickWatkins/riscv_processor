// Load store unit
module lsu #(
    parameter XLEN = 32
) (
    input logic clk,
    // Interfaces
    wishbone.MASTER data_bus,
    // Inputs
    input logic [31:2] instr,
    input logic [XLEN-1:0] ieu_result,
    input logic [XLEN-1:0] rs2_data,
    input logic stall,
    // Outputs
    output logic stalled,
    output logic [XLEN-1:0] data
);
    // TODO add write buffering
    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE
    } state;

    localparam LOAD = 5'b00000;
    localparam STORE = 5'b01000;
    
    localparam BYTE = 2'b00;
    localparam HALF = 2'b01;
    localparam WORD = 2'b10;

    localparam SIGNED = 1'b0;
    localparam UNSIGNED = 1'b1;

    state curr_state;
    state next_state;

    logic funct3 [2:0] = instr[14:12];

    assign data_bus.ADR = ieu_result;
    
    always @(*) begin
        next_state = curr_state;
        case(curr_state)
        IDLE: begin
            stalled = 0;
            data = 'x;
            data_bus.WE = 0;
            data_bus.STB = 0;
            data_bus.CYC = 0;
            if(instr[6:2] == LOAD) begin
                next_state = READ;
                stalled = 1;
                data_bus.STB = 1;
                data_bus.CYC = 1;
            end
            if(instr[6:2] == STORE) begin
                next_state = WRITE;
                data_bus.WE = 1;
                stalled = 1;
                data_bus.STB = 1;
                data_bus.CYC = 1;
            end
        end
        READ: begin
            stalled = 1;
            case(funct3)
                {SIGNED, BYTE}: data = {{(XLEN-7){data_bus.DAT_R[7]}}, data_bus.DAT_R[6:0]};
                {SIGNED, HALF}: data = {{(XLEN-15){data_bus.DAT_R[15]}}, data_bus.DAT_R[14:0]};
                {SIGNED, WORD}: data = {{(XLEN-31){data_bus.DAT_R[31]}}, data_bus.DAT_R[30:0]};
                {UNSIGNED, BYTE}: data = {{(XLEN-8){1'b0}}, data_bus.DAT_R[7:0]};
                {UNSIGNED, HALF}: data = {{(XLEN-16){1'b0}}, data_bus.DAT_R[15:0]};
                {UNSIGNED, WORD}: data = {{(XLEN-32){1'b0}}, data_bus.DAT_R[31:0]};
                default: data = 'x;
            endcase
            data_bus.WE = 0;
            data_bus.STB = 1;
            data_bus.CYC = 1;
            if(data_bus.ACK) begin
                next_state = IDLE;
                stalled = 0;
                data_bus.WE = 0;
                data_bus.STB = 0;
                data_bus.CYC = 0;
            end
        end
        WRITE: begin
            stalled = 1;
            data = 'x;
            data_bus.WE = 1;
            data_bus.STB = 1;
            data.CYC = 1;
            if(data_bus.ACK) begin
                next_state = IDLE;
                stalled = 0;
                data_bus.WE = 0;
                data_bus.STB = 0;
                data.CYC = 0;
            end
        end
        endcase
    end

    always @(posedge clk) begin
        curr_state <= next_state;
    end
endmodule
