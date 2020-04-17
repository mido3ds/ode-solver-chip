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