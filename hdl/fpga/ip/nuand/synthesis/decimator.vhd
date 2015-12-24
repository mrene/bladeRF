---
--- Component to decimate by averaging samples
---


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity decimator is
	port (
		clock : in std_logic;
		reset : in std_logic;

		in_i : in signed(15 downto 0);
		in_q : in signed(15 downto 0);
		in_valid : in std_logic;

		out_i : out signed(15 downto 0);
		out_q : out signed(15 downto 0);
		out_valid : out std_logic;

		factor : in unsigned(15 downto 0)
	);
end entity;

architecture rtl of decimator is
	signal accum_i, accum_q : signed(31 downto 0);
begin

	main : process(clock, reset)
		variable counter : unsigned(15 downto 0);
	begin
		if reset = '1' then
			accum_i <= (others => '0');
			accum_q <= (others => '0');

			counter := (others => '0');

			out_i <= (others => '0');
			out_q <= (others => '0');
			out_valid <= '0';
		elsif rising_edge(clock) then
			out_valid <= '0';

			if in_valid = '1' then
				accum_i <= accum_i + in_i;
				accum_q <= accum_i + in_q;
				counter := counter + 1;

				if counter = factor then
					out_i <= to_signed(to_integer(accum_i) / to_integer(factor), out_i'length);
					out_q <= to_signed(to_integer(accum_q) / to_integer(factor), out_q'length);
					out_valid <= '1';

					accum_i <= (others => '0');
					accum_q <= (others => '0');
					counter := (others => '0');
				end if;
			end if;
		end if;
	end process;

end architecture;
