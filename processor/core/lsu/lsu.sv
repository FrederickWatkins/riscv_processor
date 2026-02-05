// Load store unit
module lsu #(
    parameter XLEN = 32
) (
    input logic clk,

    input logic ieu_we,
    input logic ieu_re,
    input logic [2:0] funct3,
    input logic [XLEN-1:0] ieu_reg,
    input logic [XLEN-1:0] ieu_result,

    output logic stalled,
    output logic [XLEN-1:0] rd_data,

    wishbone.MASTER mm_bus
);
    localparam BYTE = 2'b00;
    localparam HALF = 2'b01;
    localparam WORD = 2'b10;

    localparam SIGNED = 1'b0;
    localparam UNSIGNED = 1'b1;

    assign mm_bus.ADR = ieu_result;
    
    logic stalled_d;
    logic [XLEN-1:0] ieu_result_d;
    logic [2:0] funct3_d;

    always @(posedge clk) begin
        if(!stalled) begin
            ieu_result_d <= ieu_result;
            funct3_d <= funct3;
        end
        stalled_d <= stalled;
    end

    always @(*) begin
        mm_bus.WE = 0;
        mm_bus.DAT_W = 'x;
        mm_bus.STB = 0;
        if(ieu_we) begin
            mm_bus.WE = 1;
            mm_bus.DAT_W = ieu_reg;
            mm_bus.STB = 1;
        end
        if(ieu_re) begin
            mm_bus.STB = 1;
        end
        if(mm_bus.ACK) begin
            mm_bus.STB = 0;
        end
    end

    always @(*) begin
        stalled = ieu_re;
        rd_data = ieu_result_d;
        casez(funct3)
        {1'b?, BYTE}: mm_bus.SEL = 'b0001;
        {1'b?, HALF}: mm_bus.SEL = 'b0011;
        {1'b?, WORD}: mm_bus.SEL = 'b1111;
        default: mm_bus.SEL ='x;
        endcase
        if(mm_bus.ACK) begin
            case(funct3_d)
            {SIGNED, BYTE}: rd_data = {{(XLEN-7){mm_bus.DAT_R[7]}}, mm_bus.DAT_R[6:0]};
            {SIGNED, HALF}: rd_data = {{(XLEN-15){mm_bus.DAT_R[15]}}, mm_bus.DAT_R[14:0]};
            {SIGNED, WORD}: rd_data = {{(XLEN-31){mm_bus.DAT_R[31]}}, mm_bus.DAT_R[30:0]};
            {UNSIGNED, BYTE}: rd_data = {{(XLEN-8){1'b0}}, mm_bus.DAT_R[7:0]};
            {UNSIGNED, HALF}: rd_data = {{(XLEN-16){1'b0}}, mm_bus.DAT_R[15:0]};
            {UNSIGNED, WORD}: rd_data = {{(XLEN-32){1'b0}}, mm_bus.DAT_R[31:0]};
            default: rd_data = 'x;
            endcase
            if(stalled_d) stalled = 0;
        end
    end


endmodule
