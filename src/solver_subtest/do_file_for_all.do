	vsim -gui work.solver_test
	add wave -position end  sim:/solver_test/clk
	add wave -position end  sim:/solver_test/rst
	force -freeze sim:/solver_test/clk 1 0, 0 {50 ns} -r 100
	force -freeze sim:/solver_test/rst 0 0
	add wave -position end  sim:/solver_test/main_fsm

	add wave -position end  sim:/solver_test/X_intm_data_in
	add wave -position end  sim:/solver_test/X_intm_data_out
	add wave -position end  sim:/solver_test/X_ware_data_in
	add wave -position end  sim:/solver_test/X_ware_data_out
	add wave -position end  sim:/solver_test/h_adapt
	add wave -position end  sim:/solver_test/L_tol
	add wave -position end  sim:/solver_test/L_nine
	add wave -position end  sim:/solver_test/fpu_add_1_in_1
	add wave -position end  sim:/solver_test/fpu_add_1_in_2
	add wave -position end  sim:/solver_test/fpu_add_1_out
	add wave -position end  sim:/solver_test/done_add_1
	add wave -position end  sim:/solver_test/enable_add_1
	add wave -position end  sim:/solver_test/posv_add_1
	add wave -position end  sim:/solver_test/fpu_mul_1_in_1
	add wave -position end  sim:/solver_test/fpu_mul_1_in_2
	add wave -position end  sim:/solver_test/fpu_mul_1_out
	add wave -position end  sim:/solver_test/done_mul_1
	add wave -position end  sim:/solver_test/enable_mul_1
	add wave -position end  sim:/solver_test/fsm_run_sum_err
	add wave -position end  sim:/solver_test/err_sum
	add wave -position end  sim:/solver_test/error_tolerance_is_good
	add wave -position end  sim:/solver_test/x_temp
	add wave -position end  sim:/solver_test/thisIsAdder_1



	add wave -position end  sim:/solver_test/X_intm_data_in
	add wave -position end  sim:/solver_test/X_intm_data_out
	add wave -position end  sim:/solver_test/X_intm_address


	add wave -position end  sim:/solver_test/X_ware_data_in
	add wave -position end  sim:/solver_test/X_ware_data_out
	add wave -position end  sim:/solver_test/X_ware_address


	add wave -position end  sim:/solver_test/err_sum
	add wave -position end  sim:/solver_test/error_tolerance_is_good
	add wave -position end  sim:/solver_test/L_nine
	add wave -position end  sim:/solver_test/h_adapt
	add wave -position end  sim:/solver_test/procedure_dumm


	add wave -position end  sim:/solver_test/fpu_mul_1_in_1
	add wave -position end  sim:/solver_test/fpu_mul_1_in_2
	add wave -position end  sim:/solver_test/fpu_mul_1_out
	add wave -position end  sim:/solver_test/done_mul_1
	add wave -position end  sim:/solver_test/enable_mul_1
	add wave -position end  sim:/solver_test/err_mul_1

	add wave -position end  sim:/solver_test/fpu_div_1_in_1
	add wave -position end  sim:/solver_test/fpu_div_1_in_2
	add wave -position end  sim:/solver_test/fpu_div_1_out
	add wave -position end  sim:/solver_test/done_div_1
	add wave -position end  sim:/solver_test/enable_div_1
	add wave -position end  sim:/solver_test/err_div_1

	add wave -position end  sim:/solver_test/h_adapt
	add wave -position end  sim:/solver_test/err_sum


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