vsim -gui work.io(rtl)
add wave -position insertpoint sim:/io/*

force -freeze sim:/io/in_state 00 0
force -freeze sim:/io/clk 0 0, 1 {50 ps} -r 100
force -freeze sim:/io/rst 1 0
run

force -freeze sim:/io/rst 0 0
force -freeze sim:/io/in_state 00 0
force -freeze sim:/io/cpu_data 01100011010010010000000100000001 0
run
force -freeze sim:/io/cpu_data 01000011001001110010000100010010 0
run
force -freeze sim:/io/cpu_data 01110010001101000001000000010000 0
run
force -freeze sim:/io/cpu_data 10010100001101100110001101001001 0
run
force -freeze sim:/io/cpu_data 00000001000000010100001100100111 0
run
force -freeze sim:/io/cpu_data 00100001000100100111001000110100 0
run
force -freeze sim:/io/cpu_data 00010000000100001001010000110110 0
run
