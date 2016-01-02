library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity complex_fir_filter is
    generic (
        INPUT_WIDTH : positive := 16;
        OUTPUT_WIDTH : positive := 16;

        ADDR_WIDTH : positive := 8;
        DATA_WIDTH : positive := 32;


        NUM_TAPS : positive := 100 ;

        ACCUM_SCALE : positive := 32;
        OUTPUT_SHIFT : positive := 12

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
    type accum_t is array( natural range <>) of signed(ACCUM_SCALE-1 downto 0);
    type coeff_t is array( natural range <>) of signed(INPUT_WIDTH-1 downto 0);

    -- Accumulators
    signal accum_i, accum_q : accum_t(NUM_TAPS-1 downto 0) := (others => (others => '0'));

    -- Coefficients storage
    signal coeff_i, coeff_q : coeff_t(NUM_TAPS-1 downto 0);

    -- Inputs
    signal in_i, in_q : signed(INPUT_WIDTH-1 downto 0);
    signal in_valid   : std_logic;

    -- Delayed inputs
    signal in_i_d, in_q_d : signed(INPUT_WIDTH-1 downto 0);
    signal in_valid_d, in_valid_d2, in_valid_d3, in_valid_d4 : std_logic;

    -- Fixed inputs (same as in_n or in_n_d if in_valid is 0)
    signal in_i_fixed, in_q_fixed : signed(INPUT_WIDTH-1 downto 0);
    signal in_valid_fixed : std_logic;

    signal out_i, out_q : signed(OUTPUT_WIDTH-1 downto 0);
    signal out_valid : std_logic;

    -- Multiplier inputs
    signal mult_datab_real, mult_datab_imag   : coeff_t(NUM_TAPS/2-1 downto 0);
    signal mult_add_real, mult_add_imag       : accum_t(NUM_TAPS/2-1 downto 0);
    signal mult_result_real, mult_result_imag : accum_t(NUM_TAPS/2-1 downto 0);
    signal mult_result_valid : std_logic_vector(NUM_TAPS/2-1 downto 0);

    signal enabled : std_logic;
begin
    
    in_i <= signed(asi_in_data(31 downto 16));
    in_q <= signed(asi_in_data(15 downto 0));
    in_valid <= asi_in_valid;

    in_i_fixed <= in_i when in_valid = '1' else in_i_d;
    in_q_fixed <= in_q when in_valid = '1' else in_q_d;
    in_valid_fixed <= in_valid when in_valid = '1' else in_valid_d;

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
                        avs_config_readdata(31 downto 1) <= (others => '0');
                        avs_config_readdata(0) <= enabled;
                    when others => 
                        if addr < NUM_TAPS then
                            avs_config_readdata <= std_logic_vector(coeff_i(addr-1)) & std_logic_vector(coeff_q(addr-1));
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
            coeff_i <= (others => (others => '0'));
            coeff_q <= (others => (others => '0'));
        elsif rising_edge(clock) then
            if avs_config_write = '1' then
                addr := to_integer(unsigned(avs_config_address));
                case addr is
                    when 0 => enabled  <= avs_config_writedata(0);
                    when others =>
                        if addr < NUM_TAPS then
                            coeff_i(addr-1) <= signed(avs_config_writedata(31 downto 16));
                            coeff_q(addr-1) <= signed(avs_config_writedata(15 downto 0));
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Generate systolic multiplier-accumulator chain
    -- Multipliers are scaled down by 2, limiting the throughput to half the clock rate
    altmac : for i in 0 to NUM_TAPS/2-1 generate
        g1 : if i /= NUM_TAPS/2-1 generate
            U_complex_mult_add : entity work.complex_mult_add
                port map(
                    clock   => clock,
                    reset   => reset or not enabled,

                    sel => not in_valid,

                    sample_valid => in_valid_fixed,
                    sample_real => in_i_fixed,
                    sample_imag => in_q_fixed,

                    coeff_a_real => coeff_i(i),
                    coeff_a_imag => coeff_q(i),

                    coeff_b_real => coeff_i(NUM_TAPS/2 + i),
                    coeff_b_imag => coeff_q(NUM_TAPS/2 + i),

                    add_a_real => accum_i(i+1),
                    add_a_imag => accum_q(i+1),

                    add_b_real => accum_i(NUM_TAPS/2 + i + 1),
                    add_b_imag => accum_q(NUM_TAPS/2 + i + 1),

                    result_a_real => accum_i(i),
                    result_a_imag => accum_q(i),

                    result_b_real => accum_i(NUM_TAPS/2 + i),
                    result_b_imag => accum_q(NUM_TAPS/2 + i)
                );
            end generate;

            g2 : if i = NUM_TAPS/2-1 generate
                U_complex_mult_add : entity work.complex_mult_add
                    port map(
                        clock   => clock,
                        reset   => reset or not enabled,

                        sel => not in_valid,

                        sample_valid => in_valid_fixed,
                        sample_real => in_i_fixed,
                        sample_imag => in_q_fixed,

                        coeff_a_real => coeff_i(i),
                        coeff_a_imag => coeff_q(i),

                        coeff_b_real => coeff_i(NUM_TAPS/2 + i),
                        coeff_b_imag => coeff_q(NUM_TAPS/2 + i),

                        add_a_real => accum_i(i+1),
                        add_a_imag => accum_q(i+1),

                        add_b_real => to_signed(0, ACCUM_SCALE),
                        add_b_imag => to_signed(0, ACCUM_SCALE),

                        result_a_real => accum_i(i),
                        result_a_imag => accum_q(i),

                        result_b_real => accum_i(NUM_TAPS/2 + i),
                        result_b_imag => accum_q(NUM_TAPS/2 + i)
                    );
            end generate;
    end generate; 

    mac : process(clock, reset)
    begin
        if reset = '1' then
            out_valid <= '0';
            in_i_d <= to_signed(0, in_i_d'length);
            in_q_d <= to_signed(0, in_q_d'length);
            in_valid_d <= '0';
            in_valid_d2 <= '0';
            in_valid_d3 <= '0';
            in_valid_d4 <= '0';

        elsif rising_edge(clock) then
            -- Delay input samples
            in_i_d <= in_i;
            in_q_d <= in_q;
            in_valid_d <= in_valid;
            in_valid_d2 <= in_valid_d;
            in_valid_d3 <= in_valid_d2;
            in_valid_d4 <= in_valid_d3;
            out_valid <= '0';

            if in_valid = '1' then
                out_q <= resize(shift_right(accum_q(0),OUTPUT_SHIFT),out_q'length);
                out_i <= resize(shift_right(accum_i(0),OUTPUT_SHIFT),out_i'length);
                out_valid <= '1';
            end if;
        end if;
    end process;
end architecture;

