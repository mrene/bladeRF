--
-- Component to rotate (up/down-shift) a signal
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work ;
    use work.cordic_p.all ;
    use work.nco_p.all ;

entity rotator is
    generic (
        ADDR_WIDTH : positive := 8;
        DATA_WIDTH : positive := 32;
		DATA_SCALE : positive := 32;
        OUTPUT_SHIFT : positive := 12
    );
    port(
        clock   :   in std_logic;
        reset   :   in std_logic;

        -- Avalon-ST Sink (Input)
        asi_in_data  : in std_logic_vector(31 downto 0);
        asi_in_valid : in std_logic;
        asi_in_ready : out std_logic;

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

architecture rtl of rotator is
	signal enabled : std_logic;
	signal dphase : signed(15 downto 0);

    signal nco_inputs   :   nco_input_t := ( dphase => (others =>'0'), valid => '0' );
    signal nco_outputs  :   nco_output_t ;

    signal ready : std_logic; -- Set whenever we get the first valid sample out of the nco

    signal in_i, in_q : signed(15 downto 0);
    signal in_valid : std_logic;

    signal out_i, out_q : signed(DATA_SCALE-1 downto 0);
    signal out_valid : std_logic;

begin

	U_nco : entity work.nco
		port map(
			clock => clock,
			reset => reset,
			inputs  => nco_inputs,
			outputs => nco_outputs
		);

	nco_inputs.dphase <= dphase;
	nco_inputs.valid  <= enabled when ready = '0' else asi_in_valid;

	-- Expose our readiness to the Avalon-ST sink interface
	asi_in_ready <= ready;

	aso_out_data <= std_logic_vector(resize(shift_right(out_i,OUTPUT_SHIFT), 16) & resize(shift_right(out_q,OUTPUT_SHIFT), 16));
	aso_out_valid <= out_valid;


	multiplier : process(clock, reset)
	begin
		if reset = '1' then
			in_i <= to_signed(0, in_i'length);
			in_q <= to_signed(0, in_q'length);
			in_valid <= '0';
			ready <= '0';
			out_i <= to_signed(0, out_i'length);
			out_q <= to_signed(0, out_q'length);
			out_valid <= '0';
		elsif rising_edge(clock) then
			-- Delay input by 1 clock so it is aligned with the nco 
			-- which outputs a sample one clock after valid is asserted
			in_i <= signed(asi_in_data(31 downto 16));
			in_q <= signed(asi_in_data(15 downto 0));
			in_valid <= asi_in_valid;

			out_valid <= '0';

			if not ready then
				-- The NCO hasn't outputted a valid sample yet
				-- Check if we have a valid NCO output 
				if nco_outputs.valid then
					ready <= '1'; 
				end if;
			else
				if in_valid = '1' then
					if nco_outputs.valid = '1' then
						out_i <= in_i * nco_outputs.re - in_q * nco_outputs.im ;
						out_q <= in_q * nco_outputs.re + in_i * nco_outputs.im ;
						out_valid <= '1';
					else
						report "Rotator is ready but the NCO output is not synchronized with the data input" severity failure;
					end if;
				end if;
			end if;
		end if;
	end process;


    mm_read : process(clock)
    begin
        if rising_edge(clock) then
            if avs_config_read = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 => 
                    	avs_config_readdata(31) <= enabled;
                    	avs_config_readdata(15 downto 0) <= std_logic_vector(dphase);
                    when others => avs_config_readdata <= x"ffffffff";
                end case;
            end if;
        end if;
    end process;

    mm_write : process(clock)
    begin
    	if reset = '1' then
    		enabled <= '0';
    		dphase <= to_signed(0, dphase'length);
        elsif rising_edge(clock) then
            if avs_config_write = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 =>
                    	enabled <= avs_config_writedata(31);
                    	dphase <= signed(avs_config_writedata(15 downto 0));
                    when others => null;
                end case;
            end if;
        end if;
    end process;

end architecture;
