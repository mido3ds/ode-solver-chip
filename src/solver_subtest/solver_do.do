	vsim -gui work.solver
	add wave -position end  sim:/solver/clk
	add wave -position end  sim:/solver/rst
	force -freeze sim:/solver/clk 1 0, 0 {50 ns} -r 100
	force -freeze sim:/solver/rst 0 0
	add wave -position end  sim:/solver/in_state
	force -freeze sim:/solver/fixed_or_var 1 0

	add wave -position end  sim:/solver/U_main_address
	add wave -position end  sim:/solver/U_main_data_in
	add wave -position end  sim:/solver/U_main_data_out
	add wave -position end  sim:/solver/X_ware_address
	add wave -position end  sim:/solver/X_ware_data_in
	add wave -position end  sim:/solver/X_ware_data_out
	add wave -position end  sim:/solver/a_coeff_address
	add wave -position end  sim:/solver/a_coeff_data_in
	add wave -position end  sim:/solver/a_coeff_data_out
	add wave -position end  sim:/solver/b_coeff_address
	add wave -position end  sim:/solver/b_coeff_data_in
	add wave -position end  sim:/solver/b_coeff_data_out
	add wave -position end  sim:/solver/X_intm_address
	add wave -position end  sim:/solver/X_intm_data_in
	add wave -position end  sim:/solver/X_intm_data_out
	add wave -position end  sim:/solver/h_adapt

	add wave -position end  sim:/solver/fsm_var_step_main

	add wave -position end  sim:/solver/fsm_run_h_2

	add wave -position end  sim:/solver/fsm_main_eq

	add wave -position end  sim:/solver/fsm_run_sum_err

	add wave -position end  sim:/solver/fsm_place_x_i_at_x_c_or_vv

	add wave -position end  sim:/solver/fsm_send_h_init




	force -freeze sim:/solver/in_state 2'h2 0
force -freeze sim:/solver/h_main 64'h0000000000000080 0


