build: build-core build-alu

build-core: processor/**.sv testbench/tb_core.cpp
	verilator -Wall -cc processor/core/core.sv -y processor/core/ieu -y processor/core/ifu -y processor/core/mmu -exe testbench/tb_core.cpp --build --trace
	clang --target=riscv32 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -T testbench/linker.ld testbench/square.c -o obj_dir/square.elf
	llvm-objcopy -O binary --only-section=.text obj_dir/square.elf obj_dir/square.bin

build-alu: processor/ieu/alu.sv testbench/tb_alu.cpp
	verilator -Wall -cc processor/core/core.sv -y processor/core/ieu -y processor/core/ifu -y processor/core/mmu -exe testbench/tb_alu.cpp --build --trace

test: test-core test-alu

test-core: build-core
	obj_dir/Vcore

test-alu: build-alu
	obj_dir/Valu

waveform-core: test-core
	nohup gtkwave obj_dir/core.vcd obj_dir/core.sav > /dev/null &

clean:
	rm -r obj_dir/
