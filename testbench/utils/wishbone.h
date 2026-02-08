#include <cstdint>

class WishboneSlave {
    public: 
    WishboneSlave(
        uint8_t* memory, unsigned int memory_size, int delay, int* curr_cycle, uint32_t* ADR,
        uint8_t* SEL, unsigned char* WE, unsigned char* STB, unsigned char* CYC, uint32_t* DAT_W, uint32_t* DAT_R,
        unsigned char* ACK
    );
    void read_from_port();
    void write_to_port();
    
    private:
    // Config
    uint8_t* memory;
    unsigned int memory_size;
    int delay;
    int last_handshake;
    bool handshake_active;
    int* curr_cycle;
    // Wishbone outputs
    uint32_t* ADR;
    uint8_t* SEL;
    unsigned char* WE;
    unsigned char* STB;
    unsigned char* CYC;
    uint32_t* DAT_W;
    // Wishbone inputs
    uint32_t* DAT_R;
    unsigned char* ACK;
};