package bus_1_enum
    typedef enum logic { 
        rs1,
        rs2
    } inputs;
endpackage

package bus_2_enum
    typedef enum logic { 
        rs1,
        rs2,
        imm
    } inputs;
endpackage

package bus_3_enum
    typedef enum logic {
        alu,
        mm,
        pc
    }
endpackage