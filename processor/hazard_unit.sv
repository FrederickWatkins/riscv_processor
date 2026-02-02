module hazard_unit (
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [4:0] rd_addr,
    output logic stall
);
    always @(*) begin
        stall = 0;
        if(rs1_addr == rd_addr | rs2_addr == rd_addr) stall = 1;
    end
endmodule
