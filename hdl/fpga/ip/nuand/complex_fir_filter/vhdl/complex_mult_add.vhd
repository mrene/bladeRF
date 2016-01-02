library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;


entity complex_mult_add is
    port (
        clock : in std_logic;
        reset : in std_logic;

        sel   : in std_logic;

        --data_valid : in std_logic;
        sample_real : in signed;
        sample_imag : in signed;
        sample_valid : in std_logic;
        
        coeff_a_real : in signed;
        coeff_a_imag : in signed;

        coeff_b_real : in signed;
        coeff_b_imag : in signed;

        add_a_real : in signed;
        add_a_imag : in signed;

        add_b_real : in signed;
        add_b_imag : in signed;

        result_a_real : out signed;
        result_a_imag : out signed;
        
        result_b_real : out signed;
        result_b_imag : out signed
        --result_valid : out std_logic
    );
end entity;
architecture rtl of complex_mult_add is
    signal tmp_result_real, tmp_result_imag : signed(result_a_real'range);
begin


    mul : process(all) is
        variable datab_real, datab_imag : signed(coeff_a_real'range);
        variable add_real, add_imag : signed(add_a_real'range);
        variable ad, bc : signed(result_a_real'range);
        variable tmp_result_real, tmp_result_imag : signed(result_a_real'range);
    begin
        if reset = '1' then
            result_a_real <= to_signed(0, result_a_real'length);
            result_a_imag <= to_signed(0, result_a_real'length);
            result_b_real <= to_signed(0, result_a_real'length);
            result_b_imag <= to_signed(0, result_a_real'length);
        elsif rising_edge(clock) then
            if sample_valid = '1' then
                if sel = '0' then
                    datab_real := coeff_a_real;
                    datab_imag := coeff_a_imag;
                    add_real := add_a_real;
                    add_imag := add_a_imag;
                else
                    datab_real := coeff_b_real;
                    datab_imag := coeff_b_imag;
                    add_real := add_b_real;
                    add_imag := add_b_imag;
                end if;

                -- Load data from input regs
                ad := sample_real * datab_imag;
                bc := sample_imag * datab_real;

                tmp_result_real := ((sample_real + sample_imag) * (datab_real - datab_imag)) + (ad - bc) + add_real;
                tmp_result_imag := ad + bc + add_imag;

                if sel = '0' then
                    result_a_real <= tmp_result_real;
                    result_a_imag <= tmp_result_imag;
                else
                    result_b_real <= tmp_result_real;
                    result_b_imag <= tmp_result_imag;
                end if;
            end if;
        end if;
    end process;
end architecture;
