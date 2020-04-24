vsim -gui work.solver_test
add wave -position end  sim:/solver_test/clk
add wave -position end  sim:/solver_test/rst
add wave -position end  sim:/solver_test/in_data
add wave -position end  sim:/solver_test/adr
add wave -position end  sim:/solver_test/X_intm_rd
add wave -position end  sim:/solver_test/X_intm_wr
add wave -position end  sim:/solver_test/X_intm_address
add wave -position end  sim:/solver_test/X_intm_data_in
add wave -position end  sim:/solver_test/X_intm_data_out
add wave -position end  sim:/solver_test/x_temp_2
add wave -position end  sim:/solver_test/main_fsm
add wave -position end  sim:/solver_test/N_counter
add wave -position end  sim:/solver_test/N_counter_2

force -freeze sim:/solver_test/clk 1 0, 0 {50 ns} -r 100
force -freeze sim:/solver_test/rst 0 0