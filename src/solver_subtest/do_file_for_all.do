	vsim -gui work.solver_test
	add wave -position end  sim:/solver_test/clk
	add wave -position end  sim:/solver_test/rst
	force -freeze sim:/solver_test/clk 1 0, 0 {50 ns} -r 100
	force -freeze sim:/solver_test/rst 0 0
	add wave -position end  sim:/solver_test/main_fsm

	add wave -position end  sim:/solver_test/X_intm_data_in
	add wave -position end  sim:/solver_test/X_intm_data_out
	add wave -position end  sim:/solver_test/X_intm_address


	add wave -position end  sim:/solver_test/X_ware_data_in
	add wave -position end  sim:/solver_test/X_ware_data_out
	add wave -position end  sim:/solver_test/X_ware_address


	add wave -position end  sim:/solver_test/fsm_place_x_i_at_x_c_or_vv



	add wave -position end  sim:/solver_test/fpu_add_1_in_1
	add wave -position end  sim:/solver_test/fpu_add_1_in_2
	add wave -position end  sim:/solver_test/fpu_add_1_out
	add wave -position end  sim:/solver_test/done_add_1
	add wave -position end  sim:/solver_test/enable_add_1
	


	add wave -position end  sim:/solver_test/a_coeff_data_in
	add wave -position end  sim:/solver_test/a_coeff_data_out
	add wave -position end  sim:/solver_test/a_coeff_address
	add wave -position end  sim:/solver_test/a_temp
	add wave -position end  sim:/solver_test/N_N

	add wave -position end  sim:/solver_test/x_temp_2
	add wave -position end  sim:/solver_test/fpu_mul_1_in_1
	add wave -position end  sim:/solver_test/fpu_mul_1_in_2
	add wave -position end  sim:/solver_test/fpu_mul_1_out
	add wave -position end  sim:/solver_test/done_mul_1
	add wave -position end  sim:/solver_test/enable_mul_1


	add wave -position end  sim:/solver_test/fpu_add_1_in_1
	add wave -position end  sim:/solver_test/fpu_add_1_in_2
	add wave -position end  sim:/solver_test/fpu_add_1_out
	add wave -position end  sim:/solver_test/done_add_1
	add wave -position end  sim:/solver_test/enable_add_1


	add wave -position end  sim:/solver_test/fsm_run_h_a





add wave -position end  sim:/solver_test/fsm_run_x_i_c