TOP_MODULE?=core
TEST_PROGRAM?=stresstest
OPTIMISATION?=O0

build: build-core build-alu

build-core: processor/**.sv testbench/core/tb_core.cpp testbench/core/core_shim.sv testbench/core/$(TEST_PROGRAM).c testbench/linker.ld testbench/utils/wishbone.cpp
	verilator -Wall -Wno-UNUSEDSIGNAL -cc processor/core/core.sv processor/core/opcodes.sv testbench/core/core_shim.sv -y processor/core/ieu \
	-y processor/core/ifu -y processor/core/lsu -y processor/core/jbu -y processor/core/rf -y \
	processor/core/hc -exe testbench/core/tb_core.cpp testbench/utils/wishbone.cpp --build --trace
	clang -w -$(OPTIMISATION) --target=riscv32 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -T \
	testbench/linker.ld testbench/entry.S testbench/core/$(TEST_PROGRAM).c -o obj_dir/$(TEST_PROGRAM).elf
	llvm-objcopy -O binary --only-section=.text obj_dir/$(TEST_PROGRAM).elf obj_dir/$(TEST_PROGRAM).bin

build-alu: processor/core/ieu/alu.sv testbench/tb_alu.cpp
	verilator -Wall -cc processor/core/ieu/alu.sv -exe testbench/tb_alu.cpp --build --trace

build-ifu: processor/core/ifu/*.sv testbench/ifu/ifu.cpp testbench/utils/wishbone.cpp
	verilator -Wall -Wno-UNUSEDSIGNAL -cc processor/core/ifu/ifu.sv processor/core/opcodes.sv testbench/ifu/ifu_shim.sv -y processor/core/ieu \
	-y processor/core/ifu -y processor/core/lsu -y processor/core/jbu -y processor/core/rf -y \
	processor/core/hc -exe testbench/ifu/ifu.cpp testbench/utils/wishbone.cpp --build --trace

build-pc: processor/core/ifu/pc.sv testbench/pc/pc.cpp testbench/utils/wishbone.cpp
	verilator -Wall -Wno-UNUSEDSIGNAL -cc processor/core/ifu/pc.sv processor/core/opcodes.sv -y processor/core/ieu \
	-y processor/core/ifu -y processor/core/lsu -y processor/core/jbu -y processor/core/rf -y \
	processor/core/hc -exe testbench/pc/pc.cpp testbench/utils/wishbone.cpp --build --trace

test: test-core test-alu

test-core: build-core
	obj_dir/Vcore obj_dir/$(TEST_PROGRAM).bin

test-alu: build-alu
	obj_dir/Valu

test-ifu: build-ifu
	obj_dir/Vifu obj_dir/$(TEST_PROGRAM).bin

test-pc: build-pc
	obj_dir/Vpc

waveform-core: test-core
	nohup gtkwave obj_dir/core.vcd testbench/sav/core.sav > /dev/null &

waveform-ifu: test-ifu
	nohup gtkwave obj_dir/ifu.vcd testbench/sav/ifu.sav > /dev/null &

waveform-pc: test-pc
	nohup gtkwave obj_dir/pc.vcd testbench/sav/pc.sav > /dev/null &

netview: processor/**.sv
	TOP_MODULE=$(TOP_MODULE) yosys -c timing/netview.tcl
	netlistsvg obj_dir/$(TOP_MODULE).json -o obj_dir/$(TOP_MODULE).svg
	loupe obj_dir/$(TOP_MODULE).svg

clean:
	rm -r obj_dir/
