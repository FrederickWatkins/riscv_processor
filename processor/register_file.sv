module register_file #(
    parameter addr_width = 5,
    parameter XLEN = 32
)(
    input wire clk,

    rf_read_port.rf rs1,
    rf_read_port.rf rs2,
    rf_write_port.rf rd
);
    logic [XLEN-1:0] ram [(1<<addr_width)-1:1];

    always @(*) begin
        rs1.data_out = (rs1.addr == 0) ? '0 : ram[rs1.addr];
        rs2.data_out = (rs2.addr == 0) ? '0 : ram[rs2.addr];
    end

    always @(posedge clk) begin
        if (rd.write_enable && (rd.addr != 0)) begin
            ram[rd.addr] <= rd.data_in;
        end
    end
endmodule
