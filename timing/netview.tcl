yosys -import

read_verilog -sv processor/core/ieu/* processor/core/ifu/* processor/core/mmu/* processor/core/core.sv 

procs; opt;        # Process and optimize the design
hierarchy -top $::env(TOP_MODULE)
procs; opt;
clean
write_json obj_dir/$::env(TOP_MODULE).json
