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

    signal accum_i, accum_q : accum_t(NUM_TAPS-1 downto 0);
    signal coeff_i, coeff_q : coeff_t(NUM_TAPS-1 downto 0);
    signal in_i, in_q : signed(INPUT_WIDTH-1 downto 0);
    signal in_valid : std_logic;

    signal out_i, out_q : signed(OUTPUT_WIDTH-1 downto 0);
    signal out_valid : std_logic;

    signal enabled : std_logic;
begin
    
    in_i <= signed(asi_in_data(31 downto 16));
    in_q <= signed(asi_in_data(15 downto 0));
    in_valid <= asi_in_valid;

    aso_out_data <= std_logic_vector(out_i) & std_logic_vector(out_q);
    aso_out_valid <= out_valid;

    mm_read : process(clock) 
        variable addr : integer;
    begin
        if rising_edge(clock) then
            if avs_config_read = '1' then
                addr := to_integer(unsigned(avs_config_address));
                case addr is
                    when 0 => 
                        avs_config_readdata(7 downto 1) <= (others => '0');
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

    mac : process(clock, reset)
    begin
        if reset = '1' then
            accum_i <= (others => (others => '0'));
            accum_q <= (others => (others => '0'));

            out_valid <= '0';
            out_i <= to_signed(0, out_i'length);
            out_q <= to_signed(0, out_q'length);

        elsif rising_edge(clock) then
            --
            out_valid <= '0';
            if in_valid = '1' then

                for i in accum_i'range loop
                    if i = accum_i'high then
                        --accum(i) <= coeff(i)*in_sample;
                        accum_i(i) <= in_i * coeff_i(i) - in_q * coeff_q(i);
                        accum_q(i) <= in_q * coeff_i(i) + in_i * coeff_q(i);
                    else
                        --accum(i) <= accum(i+1) + coeff(i)*in_sample;
                        accum_i(i) <= accum_i(i+1) + (in_i * coeff_i(i) - in_q * coeff_q(i));
                        accum_q(i) <= accum_q(i+1) + (in_q * coeff_i(i) + in_i * coeff_q(i));
                    end if;
                end loop;

                out_valid <= '1';
                out_i <= resize(shift_right(accum_i(0),OUTPUT_SHIFT),out_i'length);
                out_q <= resize(shift_right(accum_q(0),OUTPUT_SHIFT),out_q'length);
            end if;
        end if;
    end process;
end architecture;
