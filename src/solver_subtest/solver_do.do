		vsim -gui work.solver_test
		add wave -position end  sim:/solver_test/clk
		add wave -position end  sim:/solver_test/rst
		force -freeze sim:/solver_test/clk 1 0, 0 {50 ns} -r 100
		force -freeze sim:/solver_test/rst 0 0
		add wave -position end  sim:/solver_test/main_fsm

		add wave -position end  sim:/solver_test/X_intm_data_in
		add wave -position end  sim:/solver_test/X_intm_data_out
		add wave -position end  sim:/solver_test/X_intm_address

		add wave -position end  sim:/solver_test/u_main_data_in
		add wave -position end  sim:/solver_test/u_main_data_out
		add wave -position end  sim:/solver_test/u_main_address

		add wave -position end  sim:/solver_test/X_ware_data_in
		add wave -position end  sim:/solver_test/X_ware_data_out
		add wave -position end  sim:/solver_test/X_ware_address
		
		add wave -position end  sim:/solver_test/a_coeff_data_in
		add wave -position end  sim:/solver_test/a_coeff_data_out
		add wave -position end  sim:/solver_test/a_coeff_address
		
		add wave -position end  sim:/solver_test/b_coeff_data_in
		add wave -position end  sim:/solver_test/b_coeff_data_out
		add wave -position end  sim:/solver_test/b_coeff_address


		add wave -position end  sim:/solver_test/x_temp_1
		add wave -position end  sim:/solver_test/x_temp_2
		add wave -position end  sim:/solver_test/x_temp_3

		add wave -position end  sim:/solver_test/procedure_dumm
		

		add wave -position end  sim:/solver_test/fpu_add_1_in_1
		add wave -position end  sim:/solver_test/fpu_add_1_in_2
		add wave -position end  sim:/solver_test/fpu_add_1_out
		add wave -position end  sim:/solver_test/done_add_1
		add wave -position end  sim:/solver_test/enable_add_1
		add wave -position end  sim:/solver_test/fpu_mul_1_in_1
		add wave -position end  sim:/solver_test/fpu_mul_1_in_2
		add wave -position end  sim:/solver_test/fpu_mul_1_out
		add wave -position end  sim:/solver_test/done_mul_1
		add wave -position end  sim:/solver_test/enable_mul_1
		add wave -position end  sim:/solver_test/new_entry

		add wave -position end  sim:/solver_test/fsm_run_a_x
		add wave -position end  sim:/solver_test/fsm_run_x_b_u
		add wave -position end  sim:/solver_test/fsm_run_x_h
		add wave -position end  sim:/solver_test/fsm_run_x_i_c
		add wave -position end  sim:/solver_test/fsm_main_eq

