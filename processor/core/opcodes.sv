typedef enum logic [4:0] {
    LOAD = 'b00000,
    STORE = 'b01000,
    BRANCH = 'b11000,
    JALR = 'b11001,
    MISC_MEM = 'b00011,
    JAL = 'b11011,
    OP_IMM = 'b00100,
    OP = 'b01100,
    SYSTEM = 'b11100,
    AUIPC = 'b00101,
    LUI = 'b01101
} opcodes;
