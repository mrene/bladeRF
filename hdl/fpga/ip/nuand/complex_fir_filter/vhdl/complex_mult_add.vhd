library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;


entity complex_mult_add is
    port (
        clock : in std_logic;

        --data_valid : in std_logic;
        dataa_real : in signed;
        dataa_imag : in signed;
        
        datab_real : in signed;
        datab_imag : in signed;

        add_real : in signed;
        add_imag : in signed;

        result_real : out signed;
        result_imag : out signed
        --result_valid : out std_logic
    );
end entity;
architecture rtl of complex_mult_add is
    signal tmp_result_real, tmp_result_imag : signed(result_real'range);
begin


    mul : process(clock) is
        variable ad, bc : signed(result_real'range);
        variable tmp_result_real, tmp_result_imag : signed(result_real'range);
    begin
        if rising_edge(clock) then
            ad := dataa_real * datab_imag;
            bc := dataa_imag * datab_real;

            tmp_result_real := ((dataa_real + dataa_imag) * (datab_real - datab_imag)) + (ad - bc);
            tmp_result_imag := ad + bc;

            result_real <= tmp_result_real + add_real;
            result_imag <= tmp_result_imag + add_imag;
        end if;
    end process;
end architecture;
