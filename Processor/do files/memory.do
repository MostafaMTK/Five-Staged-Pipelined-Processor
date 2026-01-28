vsim -gui work.processor
add wave -position insertpoint sim:/processor/*
add wave -position insertpoint sim:/processor/DEC_Stage_inst/regfile_inst/*
mem load -i {C:/Users/Moslem/Desktop/Arch Project/Processor/assembler/output/reg.mem} /processor/DEC_Stage_inst/regfile_inst/register_file
mem load -i {C:/Users/Moslem/Desktop/Arch Project/Processor/assembler/output/Memory.mem} /processor/MEM_Fetch_Stage_inst/memory_inst/ram

force -freeze sim:/processor/clk 1 0, 0 {100000 ps} -r 200ns
force -freeze sim:/processor/rst 1 0
force -freeze sim:/processor/external_INT 0 0
force -freeze sim:/processor/input_port 00000000000000000000000000000000 0
run
run
force -freeze sim:/processor/rst 0 0
run

force -freeze sim:/processor/input_port 16#0010FE19 0
run

force -freeze sim:/processor/input_port 16#0021FFFF 0
run

force -freeze sim:/processor/input_port 16#00E5F320 0
run

force -freeze sim:/processor/input_port 16#00000000 0
run

force -freeze sim:/processor/input_port 16#000101B0 0
run