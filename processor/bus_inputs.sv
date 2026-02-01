package bus_1_enum;
    typedef enum { 
        rs1
    } inputs;
endpackage

package bus_2_enum;
    typedef enum {
        rs2,
        imm
    } inputs;
endpackage

package bus_3_enum;
    typedef enum {
        alu,
        mm,
        pc
    } inputs;
endpackage
