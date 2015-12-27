--
-- Component to rotate (up/down-shift) a signal
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity decimator_controller is
    generic (
        ADDR_WIDTH : positive := 8;
        DATA_WIDTH : positive := 32
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

architecture rtl of decimator_controller is
    signal in_i, in_q : signed(15 downto 0);
    signal in_valid   : std_logic;

    signal out_i, out_q : signed(15 downto 0);
    signal out_valid    : std_logic;

    signal ctrl_reg : std_logic_vector(31 downto 0);
    signal enabled  : std_logic;
    signal factor   : unsigned(15 downto 0);
    signal in_shift : unsigned(4 downto 0);
begin

    enabled  <= ctrl_reg(31);
    in_shift <= unsigned(ctrl_reg(20 downto 16));
    factor   <= unsigned(ctrl_reg(15 downto 0));

	aso_out_data  <= std_logic_vector(out_i & out_q) when enabled = '1' else asi_in_data;
	aso_out_valid <= out_valid when enabled = '1' else asi_in_valid;

    in_i <= signed(asi_in_data(31 downto 16));
    in_q <= signed(asi_in_data(15 downto 0));
    in_valid <= asi_in_valid;

    U_decimator : entity work.decimator
        port map(
            clock => clock,
            reset => reset,

            in_i     => in_i,
            in_q     => in_q,
            in_valid => in_valid,
            in_shift => in_shift,

            out_i     => out_i,
            out_q     => out_q,
            out_valid => out_valid,

            factor => factor
        );

    mm_read : process(clock)
    begin
        if rising_edge(clock) then
            if avs_config_read = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 => avs_config_readdata <= ctrl_reg;
                    when others => avs_config_readdata <= x"ffffffff";
                end case;
            end if;
        end if;
    end process;

    mm_write : process(clock)
    begin
    	if reset = '1' then
            ctrl_reg <= (others => '0');
            ctrl_reg(15 downto 0) <= (0 => '1', others => '0');
        elsif rising_edge(clock) then
            if avs_config_write = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 => ctrl_reg <= avs_config_writedata;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

end architecture;
