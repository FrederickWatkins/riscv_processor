build: build-core build-alu

build-core: processor/**.sv testbench/tb_core.cpp testbench/square.c testbench/linker.ld
	verilator -Wall -cc processor/core/core.sv -y processor/core/ieu -y processor/core/ifu -y processor/core/mmu -exe testbench/tb_core.cpp --build --trace
	clang -O0 --target=riscv32 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -T testbench/linker.ld testbench/entry.S testbench/square.c -o obj_dir/square.elf
	llvm-objcopy -O binary --only-section=.text obj_dir/square.elf obj_dir/square.bin

build-alu: processor/core/ieu/alu.sv testbench/tb_alu.cpp
	verilator -Wall -cc processor/core/ieu/alu.sv -exe testbench/tb_alu.cpp --build --trace

test: test-core test-alu

test-core: build-core
	obj_dir/Vcore

test-alu: build-alu
	obj_dir/Valu

waveform-core: test-core
	nohup gtkwave obj_dir/core.vcd testbench/sav/core.sav > /dev/null &

netview: processor/**.sv
	TOP_MODULE=$(TOP_MODULE) yosys -c timing/netview.tcl
	netlistsvg obj_dir/$(TOP_MODULE).json -o obj_dir/$(TOP_MODULE).svg
	loupe obj_dir/$(TOP_MODULE).svg

clean:
	rm -r obj_dir/
