vcom -2008 multiplier_tb.vhdl
vsim -gui work.multiblier_tb(testbench)
add wave -position insertpoint sim:/multiblier_tb/*
run 2000