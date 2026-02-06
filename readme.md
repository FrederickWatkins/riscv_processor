<img width="838" height="596" alt="Screenshot From 2026-02-06 16-15-09" src="https://github.com/user-attachments/assets/c3c7c470-81b7-4a66-94b1-ccd7dfe37af3" />

## CPU Cores
- Possibly heterogeneous, pipelined in-order E cores with lower clock speed, OoO P cores with higher clock speed. Each core has a separate clock, PMA and PMP unit, and cache, with the cache on the same clock as the core.

## GPU
- To start with, use software rendering on the CPU, write to the main memory and give controller the offset of the buffer.
- Base on Vortex RISCV GPGPU architecture, implement the bare minimum to write to a 13h VGA frame buffer stored in video cache. A separate SPI interface will DMA into the video cache and display the buffer not actively being written to to the LCD screen. Could instead use DAC and actual VGA. Write colour palette to memory mapped config regs. Maybe use tinydrm library to write kernel driver. Video data cache is large enough to hold two 64kb 13h buffers + some extra data.

## Buses
- All AXI4, main memory decoder separates flash, main memory and peripherals.

## Main memory
- Use behavioural verilog for simulation. If get to actually implement on fpga 

## Interrupts
- Use RISCV PLIC, or if not well supported by software, intel PIC. Memory map control table on peripheral bus. GPU also needs to be able to trigger CPU interrupts.

## Peripherals
- Maybe implement SDHCI in RTL since fairly simple, probably use IP for USB, timing is hard.

## Clock domains
- One clock domain for each core + cache
- One clock domain for main bus + ddr controller
- Peripheral bus and peripherals probably need to be on lower clock speed than main bus, but combine if possible
- Video cache and GPU on high clock, video bridge probably needs to be on slower clock so cache controller will need to have lower frequency port
