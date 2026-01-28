vsim -gui work.processor
add wave -position insertpoint sim:/processor/*
add wave -position insertpoint sim:/processor/DEC_Stage_inst/regfile_inst/*
mem load -i {C:/Users/Moslem/Desktop/Arch Project/Processor/assembler/output/reg.mem} /processor/DEC_Stage_inst/regfile_inst/register_file
mem load -i {C:/Users/Moslem/Desktop/Arch Project/Processor/assembler/output/Branch.mem} /processor/MEM_Fetch_Stage_inst/memory_inst/ram

force -freeze sim:/processor/clk 1 0, 0 {100000 ps} -r 200ns
force -freeze sim:/processor/rst 1 0
force -freeze sim:/processor/external_INT 0 0
force -freeze sim:/processor/input_port 00000000000000000000000000000000 0
run
run
force -freeze sim:/processor/rst 0 0
run

force -freeze sim:/processor/input_port 16#00030 0
run
force -freeze sim:/processor/input_port 16#00050 0
run
force -freeze sim:/processor/input_port 16#100 0
run
force -freeze sim:/processor/input_port 16#300 0
run
force -freeze sim:/processor/input_port 16#FFFF 0
run
force -freeze sim:/processor/input_port 16#FFFF 0
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
force -freeze sim:/processor/input_port 16#400 0

run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run