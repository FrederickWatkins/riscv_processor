TOP_MODULE?=core
TEST_PROGRAM?=stresstest
OPTIMISATION?=O0

build: build-core build-alu

build-core: processor/**.sv testbench/core/tb_core.cpp testbench/core/core_shim.sv testbench/core/$(TEST_PROGRAM).c testbench/linker.ld
	verilator -Wall -cc processor/core/core.sv testbench/core/core_shim.sv -y processor/core/ieu -y processor/core/ifu -y processor/core/lsu -exe testbench/core/tb_core.cpp --build --trace
	clang -w -$(OPTIMISATION) --target=riscv32 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -T testbench/linker.ld testbench/entry.S testbench/core/$(TEST_PROGRAM).c -o obj_dir/$(TEST_PROGRAM).elf
	llvm-objcopy -O binary --only-section=.text obj_dir/$(TEST_PROGRAM).elf obj_dir/$(TEST_PROGRAM).bin

build-alu: processor/core/ieu/alu.sv testbench/tb_alu.cpp
	verilator -Wall -cc processor/core/ieu/alu.sv -exe testbench/tb_alu.cpp --build --trace

test: test-core test-alu

test-core: build-core
	obj_dir/Vcore obj_dir/$(TEST_PROGRAM).bin

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
