<img width="1150" height="821" alt="Screenshot From 2026-02-06 15-31-48" src="https://github.com/user-attachments/assets/7ade2c44-4c6d-4613-9deb-cf7af50e2c0e" />

## Plan

- Implement RV32IMC and test working with basic programs
- Add memory mapped VGA buffer (vgalib drwonky) and test with more complex programs (verilator)
- Add memory mapped keyboard passthrough and continue testing
- Port to RV64IMC
- Add F/D

After this point gets much harder:
- Add Zifencei
- Add A (atomics)
- Add Zicsr (this ones gonna suck)

At this point we've reached RV64GC so can run standard code, but still need privileged architecture to do anything more complicated. Past this point gets REALLY hard:
- Privileged modes
- MMU (and probably TLB, need to add satp to zicsr)
- Add CSRs (hard to find source of exactly which are required)
- Memory mapped regs (mtime + others)
- Memory mapped peripherals (SDHCI-SDMA, maybe through AXI-Lite but probably directly memory mapped)
- Configure software - on chip boot rom, uboot spl, uboot proper, kernel

