--- Reads data from the sample domain into the processing domain
--- See: processing_bridge.vhd for the other side.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;

entity sampling_bridge is 
	port (
		clock : in std_logic;
		reset : in std_logic;

		-- Avalon-ST Output
		data     : out std_logic_vector(31 downto 0);
		valid 	 : out std_logic;


		-- FIFO from other clock domain
		rclock : out std_logic;
        rdata  : in  std_logic_vector(31 downto 0);
        rreq   : out std_logic;
        rempty : in  std_logic;
        rfull  : in  std_logic;
        rused  : in  std_logic_vector(11 downto 0)
	);
end entity;

architecture rtl of sampling_bridge is
	signal req : std_logic;
begin
	data <= rdata;

	rclock <= clock;
	rreq <= req;

	-- Make sure the output is contain a maximum of 1 complex samples per 2 clock cycles
	interleave : process(clock, reset) is
	begin
		if reset = '1' then
			req <= '0';
		elsif rising_edge(clock) then
			if req = '1' then
				req <= '0';
			elsif not rempty then
				req <= '1';
			else
				req <= '0';
			end if;
		end if;
	end process;


	-- Delay valid by 1 clock cycle after req is asserted
	validify : process(clock, reset) is
	begin
		if reset = '1' then
			valid <= '0';
		elsif rising_edge(clock) then
			valid <= req;
		end if;
	end process;

end architecture rtl;
