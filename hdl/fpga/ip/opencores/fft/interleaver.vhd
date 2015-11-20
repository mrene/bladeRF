---
--- Component to interleave the results. 
--- Input: two samples per clock, at half the clock rate
--- Output: one sample per clock, at the full clock rate
---
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_len.all;
use work.icpx.all;
use work.all;


entity interleaver is
	port (
		clk : in std_logic;
		rst_n : in std_logic;

		-- Input port A
		in_valid_a : in std_logic;
		in_data_a : in icpx_number;

		-- Input port B
		in_valid_b : in std_logic;
		in_data_b : in icpx_number;

		-- Output port
		data : out icpx_number;
		valid : out std_logic
	);

end interleaver;


architecture rtl of interleaver is
	signal in_data_b_delayed : icpx_number;
	signal in_valid_b_delayed : std_logic;
begin
	
	data <= in_data_a when in_valid_a = '1' else 
			in_data_b_delayed when in_valid_b_delayed = '1' else
			icpx_zero;

	valid <= '1' when in_valid_a = '1' else
			 '1' when in_valid_b_delayed = '1' else
			 '0';
	
	main : process(clk, rst_n) is
	begin
		-- Asynchronous reset
		if rst_n = '0' then
			in_data_b_delayed <= icpx_zero;
			in_valid_b_delayed <= '0';
		elsif rising_edge(clk) then
			if in_valid_a = '1' then
				in_data_b_delayed <= in_data_b;
				in_valid_b_delayed <= in_valid_b;
			end if;
		end if;
	end process main;
end rtl;
