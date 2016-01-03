library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity complex_fir_filter is
    generic (
        ADDR_WIDTH : positive := 8;
        DATA_WIDTH : positive := 32;

        NUM_TAPS : positive := 60
    );
    port(
        clock   :   in std_logic;
        reset   :   in std_logic;

        -- Avalon-ST Sink (Input)
        asi_in_data  : in std_logic_vector(31 downto 0);
        asi_in_valid : in std_logic;

        -- Avalon-ST Source (Output)
        aso_out_data          : out std_logic_vector(31 downto 0);
        aso_out_valid         : out std_logic; 

        -- Avalon-MM Slave
        avs_config_address       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        avs_config_read          : in  std_logic;
        avs_config_readdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        avs_config_write         : in  std_logic;
        avs_config_writedata     : in  std_logic_vector(DATA_WIDTH-1 downto 0)
    );

end entity;

architecture systolic of complex_fir_filter is
    type complex_fixed32_t is record
        re : signed(31 downto 0);
        im : signed(31 downto 0);
    end record;
    type complex_fixed32_array_t is array(natural range <>) of complex_fixed32_t;

    type complex_fixed_t is record
        re : signed(15 downto 0);
        im : signed(15 downto 0);
    end record;
    type complex_fixed_array_t is array(natural range <>) of complex_fixed_t;


    type complex_mult_partial_01_t is record
        ad : signed(31 downto 0);
        bc : signed(31 downto 0);
        tmp1 : signed(15 downto 0);
        tmp2 : signed(15 downto 0);
    end record;
    type complex_mult_partial_01_array_t is array(natural range <>) of complex_mult_partial_01_t;

    type complex_mult_partial_02_t is record
        adpbc : signed(31 downto 0);
        admbc : signed(31 downto 0);

        tmp3 : signed(31 downto 0);
    end record;
    type complex_mult_partial_02_array_t is array(natural range <>) of complex_mult_partial_02_t;

    type complex_mult_partial_03_t is record
        tmp_result : complex_fixed32_t;
    end record;
    type complex_mult_partial_03_array_t is array(natural range <>) of complex_mult_partial_03_t;


    -- Add an extra accum element to simplify logic
    signal accum : complex_fixed32_array_t(NUM_TAPS downto 0);
    signal intermediates_01 : complex_mult_partial_01_array_t(NUM_TAPS-1 downto 0);
    signal intermediates_02 : complex_mult_partial_02_array_t(NUM_TAPS-1 downto 0);
    signal intermediates_03 : complex_mult_partial_03_array_t(NUM_TAPS-1 downto 0);
    signal coeff : complex_fixed_array_t(NUM_TAPS-1 downto 0);

    signal in_sample, in_sample_d : complex_fixed_t;
    signal in_sample_fixed : complex_fixed_t;
    signal in_valid : std_logic;
    signal in_valid_d, in_valid_d2, in_valid_d3, in_valid_d4 : std_logic;

    signal out_i, out_q : signed(15 downto 0);
    signal out_valid : std_logic;

    function cmult_add(
        dataa, datab : complex_fixed_t;
        add : complex_fixed32_t
    ) return complex_fixed32_t is
        variable ad, bc : signed(31 downto 0);
        variable tmp_result_real, tmp_result_imag : signed(31 downto 0);
        variable rv : complex_fixed32_t := (to_signed(0,32),to_signed(0,32));
    begin
        ad := dataa.re * datab.im;
        bc := dataa.im * datab.re;

        tmp_result_real := ((dataa.re + dataa.im) * (datab.re - datab.im)) + (ad - bc);
        tmp_result_imag := ad + bc;

        rv.re := tmp_result_real + add.re;
        rv.im := tmp_result_imag + add.im;

        return rv;
    end function;

---------------------------------------------------------------------------------------------

    function cmult_add_partial_01(
        dataa, datab : complex_fixed_t
    ) return complex_mult_partial_01_t is
        variable tmp1, tmp2 : signed(15 downto 0);
        variable rv : complex_mult_partial_01_t;
    begin
        -- Clock 1
        rv.ad := dataa.re * datab.im;
        rv.bc := dataa.im * datab.re;

        rv.tmp1 := dataa.re + dataa.im;
        rv.tmp2 := datab.re - datab.im;

        return rv;
    end function;

    function cmult_add_partial_02(
        partial : complex_mult_partial_01_t
    ) return complex_mult_partial_02_t is
        variable rv : complex_mult_partial_02_t;
    begin
        rv.tmp3 := partial.tmp1 * partial.tmp2;

        rv.admbc := partial.ad - partial.bc;
        rv.adpbc := partial.ad + partial.bc;

        return rv;
    end function;

    function cmult_add_partial_03(
        partial : complex_mult_partial_02_t
    ) return complex_mult_partial_03_t is
        variable rv : complex_mult_partial_03_t;
    begin
        rv.tmp_result.re := partial.tmp3 + partial.admbc;
        rv.tmp_result.im := partial.adpbc;

        return rv;
    end function;


    function cmult_add_partial_04(
        partial : complex_mult_partial_03_t;
        add : complex_fixed32_t
    ) return complex_fixed32_t is
        variable tmp_result : complex_fixed32_t;
        variable rv : complex_fixed32_t;
    begin
        rv.re := partial.tmp_result.re + add.re;
        rv.im := partial.tmp_result.im + add.im;

        return rv;
    end function;


    function complex_zero return complex_fixed_t is
        variable rv: complex_fixed_t := (to_signed(0,16),to_signed(0,16));
    begin
        return rv;
    end function;

    function complex32_zero return complex_fixed32_t is
        variable rv: complex_fixed32_t := (to_signed(0,32),to_signed(0,32));
    begin
        return rv;
    end function;

    signal ctrl_reg : std_logic_vector(31 downto 0);
    signal enabled : std_logic;
    signal out_shift : unsigned(7 downto 0);
begin
    enabled  <= ctrl_reg(0);
    out_shift <= unsigned(ctrl_reg(31 downto 24));
    
    in_sample.re <= signed(asi_in_data(31 downto 16));
    in_sample.im <= signed(asi_in_data(15 downto 0));
    in_valid <= asi_in_valid;

    in_sample_fixed <= in_sample when in_valid ='1' else in_sample_d when in_valid_d = '1' else complex_zero;

    aso_out_data <= std_logic_vector(out_i) & std_logic_vector(out_q) when enabled = '1' else asi_in_data;
    aso_out_valid <= out_valid when enabled = '1' else asi_in_valid;

    mm_read : process(clock) 
        variable addr : integer;
    begin
        if rising_edge(clock) then
            if avs_config_read = '1' then
                addr := to_integer(unsigned(avs_config_address));
                case addr is
                    when 0 => 
                        avs_config_readdata <= ctrl_reg;
                    when others => 
                        if addr < NUM_TAPS then
                            avs_config_readdata <= std_logic_vector(coeff(addr-1).re) & std_logic_vector(coeff(addr-1).im);
                        else
                            avs_config_readdata <= x"ffffffff";
                        end if;
                end case;
            end if;
        end if;
    end process;

    mm_write : process(clock, reset)
        variable addr : integer;
    begin
        if reset = '1' then
            for i in coeff'range loop
                coeff(i) <= complex_zero;
            end loop;

            ctrl_reg <= (others => '0');
            ctrl_reg(31 downto 24) <= std_logic_vector(to_unsigned(12, 8));
        elsif rising_edge(clock) then
            if avs_config_write = '1' then
                addr := to_integer(unsigned(avs_config_address));
                case addr is
                    when 0 => ctrl_reg  <= avs_config_writedata;
                    when others =>
                        if addr < NUM_TAPS then
                            coeff(addr-1).re <= signed(avs_config_writedata(31 downto 16));
                            coeff(addr-1).im <= signed(avs_config_writedata(15 downto 0));
                        end if;
                end case;
            end if;
        end if;
    end process;

    mac : process(clock, reset)
        variable index_01 : integer;
        variable index_02 : integer;
        variable index_03 : integer;
        variable index_04 : integer;
    begin
        if reset = '1' or enabled = '0' then
            for i in accum'range loop
                accum(i) <= complex32_zero;
            end loop;

            out_valid <= '0';
            out_i <= to_signed(0, out_i'length);
            out_q <= to_signed(0, out_q'length);
            index_01 := 0;
            index_02 := 0;
            index_03 := 0;
            index_04 := 0;

            in_valid_d <= '0';
            in_valid_d2 <= '0';
            in_valid_d3 <= '0';
            in_valid_d4 <= '0';

        elsif rising_edge(clock) then
            --
            out_valid <= '0';
            in_valid_d <= in_valid;
            in_valid_d2 <= in_valid_d; 
            in_valid_d3 <= in_valid_d2;
            in_valid_d4 <= in_valid_d3;
            in_sample_d <= in_sample;

            if in_valid = '1' then
                index_01 := 0;
            elsif in_valid_d = '1' then
                index_01 := NUM_TAPS/2;
            end if;

            if in_valid_d = '1' then
                index_02 := 0;
            elsif in_valid_d2 = '1' then
                index_02 := NUM_TAPS/2;
            end if;

            if in_valid_d2 = '1' then
                index_03 := 0;
            elsif in_valid_d3 = '1' then
                index_03 := NUM_TAPS/2;
            end if;

            if in_valid_d3 = '1' then
                index_04 := 0;
            elsif in_valid_d4 = '1' then
                index_04 := NUM_TAPS/2;
            end if;


            -- Perform the first clock of the pipelined operation
            if in_valid = '1' or in_valid_d = '1' then
                for i in NUM_TAPS/2-1 downto 0 loop
                    --accum(i) <= accum(i+1) + coeff(i)*in_sample;
                    intermediates_01(index_01 + i) <= cmult_add_partial_01(coeff(index_01 + i), in_sample_fixed);
                end loop;
            end if;

            -- Perform the 2nd clock of the pipeline operation
            if in_valid_d = '1' or in_valid_d2 = '1' then
                for i in NUM_TAPS/2-1 downto 0 loop
                    intermediates_02(index_02 + i) <= cmult_add_partial_02(intermediates_01(index_02+i));
                end loop;
            end if;

            -- Perform the 3rd clock of the pipeline operation
            if in_valid_d2 = '1' or in_valid_d3 = '1' then
                for i in NUM_TAPS/2-1 downto 0 loop
                    intermediates_03(index_03 + i) <= cmult_add_partial_03(intermediates_02(index_03+i));
                end loop;
            end if;

            -- Perform the 4th clock of the pipeline operation
            if in_valid_d3 = '1' or in_valid_d4 = '1' then
                for i in NUM_TAPS/2-1 downto 0 loop
                    accum(index_04 + i) <= cmult_add_partial_04(intermediates_03(index_04+i), accum(index_04+i+1));
                end loop;
            end if;

            if in_valid_d3 = '1' then
                out_valid <= '1';
                out_i <= resize(shift_right(accum(0).re, to_integer(out_shift)), out_i'length);
                out_q <= resize(shift_right(accum(0).im, to_integer(out_shift)), out_q'length);
            end if;
        end if;
    end process;
end architecture;
