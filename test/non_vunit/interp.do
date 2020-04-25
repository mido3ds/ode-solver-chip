vsim -gui work.interp(rtl)
add wave -position insertpoint sim:/interp/*

force sim:/interp/rst 1 0
run
run 

force sim:/interp/rst 0 0
force sim:/interp/clk 1 0, 0 {50 ps} -r 100
force sim:/interp/in_state 00 0

force sim:/interp/adr 0000000000000000 0
force sim:/interp/in_data 00010100010100010100000000000000 0
run

force sim:/interp/adr 0000000000000001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0000000000000010 0
force sim:/interp/in_data 00000000000000000000000001000000 0
run 

force sim:/interp/adr 0010100101101101 0
force sim:/interp/in_data 00000000000000000000000000000000 0 
run 

force sim:/interp/adr 0010100101101110 0
run

force sim:/interp/adr 0010100101101111 0
run

force sim:/interp/adr 0010100101110000 0
run

force sim:/interp/adr 0010100101110001 0
run

force sim:/interp/adr 0010100101110010 0
run

force sim:/interp/adr 0010100101110011 0
run

force sim:/interp/adr 0010100101110100 0
run

force sim:/interp/adr 0010100101110101 0
run

force sim:/interp/adr 0010100101110110 0
run

force sim:/interp/adr 0010100111010001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run

force sim:/interp/adr 0010100111010010 0
force sim:/interp/in_data 00000000000000000000000010000000 0
run 

force sim:/interp/adr 0010100111010011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111010100 0
force sim:/interp/in_data 00000000000000000000000110000000 0
run

force sim:/interp/adr 0010100111010101 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111010110 0
force sim:/interp/in_data 00000000000000000000001010000000 0
run 

force sim:/interp/adr 0010100111010111 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111011000 0
force sim:/interp/in_data 00000000000000000000001010000000 0
run

force sim:/interp/adr 0010100111011001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run

force sim:/interp/adr 0010100111011010 0
force sim:/interp/in_data 00000000000000000000010010000000 0
run 




force sim:/interp/adr 0010100111011011 0 	
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111011100 0
force sim:/interp/in_data 00000000000000000000011110000000 0
run 

force sim:/interp/adr 0010100111011101 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111011110 0
force sim:/interp/in_data 00000000000000000000011110000000 0
run 

force sim:/interp/adr 0010100111011111 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111100000 0
force sim:/interp/in_data 00000000000000000000011110000000 0
run 

force sim:/interp/adr 0010100111100001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111100010 0
force sim:/interp/in_data 00000000000000000000011110000000 0
run 

force sim:/interp/adr 0010100111100011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010100111100100 0
force sim:/interp/in_data 00000000000000000000011110000000 0
run 




force sim:/interp/adr 0010101000111111 0 	
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001000000 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001000001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001000010 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001000011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001000100 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001000101 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001000110 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001000111 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001000 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 




force sim:/interp/adr 0010101001000011 0 	
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001000100 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001000101 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001000110 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001000111 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001000 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001001001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001010 0
force sim:/interp/in_data 00000000000000000000011110000000 0
run 

force sim:/interp/adr 0010101001001011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001100 0
force sim:/interp/in_data 00000000000000000000011110000000 0
run 




force sim:/interp/adr 0010101001000111 0 	
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001000 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001001001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001010 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001001011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001100 0
force sim:/interp/in_data 00000000000000000111111110000000 0
run 

force sim:/interp/adr 0010101001001101 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001110 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001111 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001010000 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 




force sim:/interp/adr 0010101001001011 0 	
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001100 0
force sim:/interp/in_data 11111111111111111111111111111111 0
run 

force sim:/interp/adr 0010101001001101 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001001110 0
force sim:/interp/in_data 11111111111111111111111111111111 0
run 

force sim:/interp/adr 0010101001001111 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001010000 0
force sim:/interp/in_data 11111111111111111111111111111111 0
run 

force sim:/interp/adr 0010101001010001 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001010010 0
force sim:/interp/in_data 11111111111111111111111111111111 0
run 

force sim:/interp/adr 0010101001010011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010101001010100 0
force sim:/interp/in_data 11111111111111111111111111111111 0
run 


force sim:/interp/in_state 10 0
force sim:/interp/adr 0010110000110011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010110000110100 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run

force sim:/interp/adr zzzzzzzzzzzzzzzz 0
force sim:/interp/in_data zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 0
run 1500

force sim:/interp/adr 0010110000110011 0
force sim:/interp/in_data 00000000000000000000000000000000 0
run 

force sim:/interp/adr 0010110000110100 0
force sim:/interp/in_data 00000000000000000000000011100000 0
run

force sim:/interp/adr zzzzzzzzzzzzzzzz 0
force sim:/interp/in_data zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 0
run 50000