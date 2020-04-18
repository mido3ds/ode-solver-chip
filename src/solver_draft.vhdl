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









        --4.5: writes result_a_temp --> A[i,i+1]
    write_a : process(clk, run_a_loop, write_a_coeff)
    begin
        -- result is at result_a_temp
        -- we can't read and write at the same time, so add_2 is free
        if rising_edge(clk) and run_a_loop = '1' and write_a_coeff = '1' then
            if a_high = '0' then
                if decrement_a_address = '0' then 
                    a_coeff_wr <= '1';
                    a_coeff_data_in <= result_a_temp (63 downto 32) ;
                    a_high <= '1';
                    increment_a_address <= '1';
                end if;
            else
                if increment_a_address = '0' then
                    a_coeff_wr <= '1';
                    a_coeff_data_in <= result_a_temp (31 downto 0) ;
                    a_high <= '0';
                    increment_a_address <= '1';
                end if;
            end if;
        end if;
        a_coeff_wr <= '0';
    end process ; -- write_a_coeff



    --4.3: responsible for reading coeff A at addresses [x,x+1]
    --and update the address pointer
    read_a_coeff : process(clk, run_a_loop, a_is_read, write_a_coeff)
    begin
        if rising_edge(clk) and run_a_loop = '1' and a_is_read = '0' and write_a_coeff = '0' then
            if a_high = '0' then
                if increment_a_address = '0' then
                    --reading the low part
                    a_coeff_rd <= '1';
                    a_temp(63 downto 32) <= a_coeff_data_out;
                    a_high <= '1';
                    increment_a_address <= '1';
                end if;
            else
                if increment_a_address = '0' then
                    a_coeff_rd <= '1';
                    a_temp(31 downto 0) <= a_coeff_data_out;
                    a_high <= '0';
                    a_is_read <= '1';
                    decrement_a_address <= '1';
                end if;
            end if;
        end if;
        --rga3 el-7aga zay ma kant!
        a_coeff_rd <= '0';
    end process ; -- read_a_coeff




    --4.7: responsible for reading coeff B at addresses [x,x+1]
    --and update the address pointer
    read_b_coeff : process(clk, run_b_loop, b_is_read, write_b_coeff)
    begin
        if rising_edge(clk) and run_b_loop = '1' and b_is_read = '0' and write_b_coeff = '0' then
            if b_high = '0' then
                if increment_b_address = '0' then
                    --reading the low part
                    b_coeff_rd <= '1';
                    b_temp(63 downto 32) <= b_coeff_data_out;
                    b_high <= '1';
                    increment_b_address <= '1';
                end if;
            else
                if increment_b_address = '0' then
                    b_coeff_rd <= '1';
                    b_temp(31 downto 0) <= b_coeff_data_out;
                    b_high <= '0';
                    b_is_read <= '1';
                    decrement_b_address <= '1';
                end if;
            end if;
        end if;
        --rga3 el-7aga zay ma kant!
        b_coeff_rd <= '0';
    end process ; -- read_a_coeff

    --4.8: writes result_b_temp to memory
    write_b : process(clk, run_b_loop, write_b_coeff)
    begin
        -- result is at result_a_temp
        -- we can't read and write at the same time, so add_2 is free
        if rising_edge(clk) and run_b_loop = '1' and write_b_coeff = '1' then
            if b_high = '0' then
                if decrement_b_address = '0' then
                    b_coeff_wr <= '1';
                    b_coeff_data_in <= result_b_temp (63 downto 32) ;
                    b_high <= '1';
                    increment_b_address <= '1';
                end if;
            else
                if increment_b_address = '0' then 
                    b_coeff_wr <= '1';
                    b_coeff_data_in <= result_b_temp (31 downto 0) ;
                    b_high <= '0';
                    increment_b_address <= '1';
                end if;
            end if;
        end if;
        b_coeff_wr <= '0';
    end process ; -- write_a_coeff

    
    
    --4.11: increments address of part B
    inc_b_address : process( clk, increment_b_address,done_add_2 )
    begin
        if rising_edge (clk) and increment_b_address = '1' then
            if done_add_2 = '0' then
                fpu_add_2_in_1 <= b_coeff_address;
                fpu_add_2_in_2 <= X"0001";
                enable_add_2 <= '1';
            else
                b_coeff_address <= fpu_add_2_out;
                enable_add_2 <= '0';
                increment_b_address <='0';
            end if;
        end if;
    end process ; -- inc_b_address

    --4.12: decrements address of part B
    dec_b_address : process( clk, decrement_b_address, done_sub_1)
    begin
        if rising_edge (clk) and decrement_b_address = '1' then
            if done_sub_1 = '0' then
                fpu_sub_1_in_1 <= b_coeff_address;
                fpu_sub_1_in_2 <= X"0001";
                enable_sub_1 <= '1'; 
            else
                b_coeff_address <= fpu_add_2_out;
                enable_sub_1 <= '0';
                decrement_b_address <='0';
            end if;
        end if;
    end process ; -- dec_b_address