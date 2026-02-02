build: processor/*.sv
	verilator -Wall -cc processor/bus_inputs.sv processor/control/expander.sv processor/control/control_unit.sv processor/alu.sv processor/processor.sv \
	--exe testbench/tb_alu.cpp

test: build
	$(MAKE) -C obj_dir -f Valu.mk

run: test
	./obj_dir/Valu

build-alu: processor/alu.sv
	verilator -Wall -cc processor/alu.sv --exe testbench/tb_alu.cpp

test-alu: build-alu
	$(MAKE) -C obj_dir -f Valu.mk

run-alu: test-alu
	./obj_dir/Valu

clean:
	rm -rf obj_dir/