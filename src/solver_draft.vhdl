fpu_unit_1 : entity work.fpu(rtl)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_sig_1,
            in_a      => fpu_1_in_1,
            in_b      => fpu_1_in_2,
            out_c     => fpu_1_out,
            operation => operation_sig_1,
            done      => done_sig_1,
            err       => err_sig_1,
            zero      => zero_sig_1,
            posv      => posv_sig_1
        );
    fpu_unit_2 : entity work.fpu(rtl)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_sig_2,
            in_a      => fpu_2_in_1,
            in_b      => fpu_2_in_2,
            out_c     => fpu_2_out,
            operation => operation_sig_2,
            done      => done_sig_2,
            err       => err_sig_2,
            zero      => zero_sig_2,
            posv      => posv_sig_2
        );



        case adr is
                --Header
                when X"0000" =>
                    address_pointer <= "001";
                --H
                when X"0001" =>
                    address_pointer <= "010";
                --error ie. Tolerance
                when X"0003" =>
                    address_pointer <= "011";
                --A
                when X"0005" =>
                    address_pointer <= "100";
                --B
                when X"138D" =>
                    address_pointer <= "101";
                --X0 ie. X_w[0]
                when X"2715" =>
                    address_pointer <= "110";
                --U0 ie. Umain
                when X"296D" =>
                    address_pointer <= "111";
                -- Not our address :D
                when others => 
                    address_pointer <= "000";
            end case;

variable a_of_i : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
    variable h_var  : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
    
    begin
        if rising_edge(clk) and run_a_loop = '1' then
            a_coeff_address <= (others => '0');
            h_main_address <= (others => '0');
            for I in 0 to N_N-1 loop
                --each element(64) of A, multiply by h and add 1
                a_coeff_rd <= '1';
                h_main_rd  <= '1';
                for j in 0 to 1 loop
                    a_of_i(63-(j*32) downto 32-(j*32)) := a_coeff_data_out;
                    fpu_add_2_in_1 <= a_coeff_address;
                    fpu_add_2_in_2 <= X"0001";
                    enable_add_2   <= '1';
                    a_coeff_address <= fpu_add_2_out;

                    h_var (63-(j*32) downto 32-(j*32)) := h_main_data_out; 
                    fpu_add_3_in_1 <= h_main_address;
                    fpu_add_3_in_2 <= X"0001";
                    enable_add_3   <= '1';
                    h_main_address <= fpu_add_3_out;
                end loop ; 
                enable_add_2   <= '0';
                enable_add_3   <= '0';


            end loop;

        end if;
        run_a_loop <= '0';