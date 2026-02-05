interface wishbone #(
    parameter XLEN = 32
);
    logic [XLEN-1:0] ADR;
    logic [XLEN-1:0] DAT_W;
    logic [XLEN-1:0] DAT_R;
    logic [XLEN/8-1:0] SEL;
    logic WE, STB, ACK, CYC;

    modport MASTER (
        output ADR,
        output SEL,
        output WE,
        output STB,
        output CYC,
        output DAT_W,
        input DAT_R,
        input ACK
    );

    modport SLAVE (
        input ADR,
        input SEL,
        input WE,
        input STB,
        input DAT_W,
        output DAT_R,
        output ACK
    );

endinterface
