---
--- Qsys component exposing the multiplexer interface
---

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;
    use work.fft_len.all;
    use work.icpx.all;
    use work.fft_support_pkg.all;
    use work.multiplexer_p.all;

entity multiplexer_controler is
    generic (
        -- Config register settings
        ADDR_WIDTH : positive := 8;
        DATA_WIDTH : positive := 8
    );
	port(
		clock : in std_logic;
		reset : in std_logic;


    	-- Avalon-ST Sink (Input0)
        asi_in0_data  : in std_logic_vector(31 downto 0);
        asi_in0_valid : in std_logic;
        asi_in0_startofpacket : in std_logic;
        asi_in0_endofpacket   : in std_logic;

    	-- Avalon-ST Sink (Input1)
        asi_in1_data  : in std_logic_vector(31 downto 0);
        asi_in1_valid : in std_logic;
        asi_in1_startofpacket : in std_logic;
        asi_in1_endofpacket   : in std_logic;

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

architecture rtl of multiplexer_controler is
	signal enabled	: std_logic_vector(1 downto 0) := (others => '1');
begin

	U_muxer : entity work.multiplexer
		generic map (
			PACKET_LEN => 256,
			NUM_STREAMS => 2
		)
		port map (
			clock => clock,
			reset => reset,

			data => aso_out_data,
			valid => aso_out_valid,

			-- All inputs are coming from the same clock domain right now
			inputs(0).clock => clock,
			inputs(0).data => asi_in0_data,
			inputs(0).valid => asi_in0_valid,
			inputs(0).enabled => enabled(0),
			inputs(0).startofpacket => asi_in0_startofpacket,
			inputs(0).endofpacket => asi_in1_startofpacket,

			inputs(1).clock => clock,
			inputs(1).data => asi_in1_data,
			inputs(1).valid => asi_in1_valid,
			inputs(1).enabled => enabled(1),
			inputs(1).startofpacket => asi_in1_startofpacket,
			inputs(1).endofpacket => asi_in1_endofpacket
		);

	rst : process(reset)
	begin
		if reset = '1' then
			enabled <= (others => '1');
		end if;
	end process;

    mm_read : process(clock) 
    begin
        if rising_edge(clock) then
            if avs_config_read = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 => 
                    	avs_config_readdata(7 downto 2) <= (others => '0');
                    	avs_config_readdata(1 downto 0) <= enabled;
                    when others => avs_config_readdata <= x"ff";
                end case;
            end if;
        end if;
    end process;

    mm_write : process(clock)
    begin
        if rising_edge(clock) then
            if avs_config_write = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 => enabled  <= avs_config_writedata(1 downto 0);
                    when others => null;
                end case;
            end if;
        end if;
    end process;
end architecture;


