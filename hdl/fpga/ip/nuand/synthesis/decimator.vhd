---
--- Component to decimate by averaging samples
---


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library lpm;
	use lpm.lpm_components.all;

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

		factor : in unsigned(15 downto 0);
		in_shift : in unsigned(4 downto 0)
	);
end entity;

architecture rtl of decimator is

	component lpm_divide
	generic (
		lpm_widthn		: natural;
		lpm_widthd		: natural;
		lpm_pipeline	: natural;
		lpm_nrepresentation		: string;
		lpm_drepresentation		: string
	);
	port (
			clock   : in std_logic;
			clken   : in std_logic;
			aclr    : in std_logic;
			denom	: in std_logic_vector (15 downto 0);
			quotient: out std_logic_vector (31 downto 0);
			remain	: out std_logic_vector (15 downto 0);
			numer	: in std_logic_vector (31 downto 0)
	);
	end component;

	signal accum_i, accum_q : signed(31 downto 0);
	signal div_numer_i, div_quotient_i : std_logic_vector(31 downto 0);
	signal div_numer_q, div_quotient_q : std_logic_vector(31 downto 0);

	signal div_denom   : std_logic_vector(15 downto 0);
	signal div_remain_i, div_remain_q  : std_logic_vector(15 downto 0);
	signal out_valid_d0, out_valid_d1, out_valid_d2  : std_logic;
	signal out_valid_d3, out_valid_d4, out_valid_d5  : std_logic;
	signal out_valid_d6, out_valid_d7, out_valid_d8  : std_logic;
	signal out_valid_d9, out_valid_d10, out_valid_d11  : std_logic;
begin

	-- Manually instanciate lpm_divide to specify the LPM_PIPELINE parameter
	U_divide_i : component lpm_divide
		generic map (
			LPM_WIDTHN   => 32, -- Width of numer and quotient
			LPM_WIDTHD   => 16, -- Width of denom and remain
			LPM_PIPELINE => 12,   -- Clock cycles before output is valid,
			LPM_NREPRESENTATION => "SIGNED",
			LPM_DREPRESENTATION => "UNSIGNED"
		)
		port map (
			clock    => clock,
			clken    => '1',
			aclr     => reset,
			numer    => div_numer_i,
			denom    => div_denom,
			quotient => div_quotient_i,
			remain   => div_remain_i
		) ;

	U_divide_q : component lpm_divide
		generic map (
			LPM_WIDTHN   => 32, -- Width of numer and quotient
			LPM_WIDTHD   => 16, -- Width of denom and remain
			LPM_PIPELINE => 12,   -- Clock cycles before output is valid
			LPM_NREPRESENTATION => "SIGNED",
			LPM_DREPRESENTATION => "UNSIGNED"
		)
		port map (
			clock    => clock,
			clken    => '1',
			aclr     => reset,
			numer    => div_numer_q,
			denom    => div_denom,
			quotient => div_quotient_q,
			remain   => div_remain_q
		) ;


	out_i <= resize(signed(div_quotient_i), out_i'length) when out_valid = '1' else (others => '0');
	out_q <= resize(signed(div_quotient_q), out_q'length) when out_valid = '1' else (others => '0');

	--div_numer_i <= std_logic_vector(accum_i)  when rising_edge(clock);
	--div_numer_q <= std_logic_vector(accum_q) when rising_edge(clock);

	div_denom <= std_logic_vector(factor) ;

	main : process(clock, reset)
		variable counter : unsigned(15 downto 0);
	begin
		if reset = '1' then
			accum_i <= (others => '0');
			accum_q <= (others => '0');

			counter := (others => '0');

			out_valid <= '0';
			out_valid_d0 <= '0';
			out_valid_d1 <= '0';
			out_valid_d2 <= '0';
			out_valid_d3 <= '0';
			out_valid_d4 <= '0';
			out_valid_d5 <= '0';
			out_valid_d6 <= '0';
			out_valid_d7 <= '0';
			out_valid_d8 <= '0';
			out_valid_d9 <= '0';
			out_valid_d10 <= '0';
			out_valid_d11 <= '0';


			div_numer_i <= (others => '0');
			div_numer_q <= (others => '0');
		elsif rising_edge(clock) then

			-- Sample delays
			out_valid <= out_valid_d11;

			out_valid_d11 <= out_valid_d10;
			out_valid_d10 <= out_valid_d9;
			out_valid_d9 <= out_valid_d8;
			out_valid_d8 <= out_valid_d7;
			out_valid_d7 <= out_valid_d6;
			out_valid_d6 <= out_valid_d5;
			out_valid_d5 <= out_valid_d4;
			out_valid_d4 <= out_valid_d3;
			out_valid_d3 <= out_valid_d2;
			out_valid_d2 <= out_valid_d1;
			out_valid_d1 <= out_valid_d0;

			out_valid_d0 <= '0';

			if in_valid = '1' then
				counter := counter + 1;

				if counter = factor then
					--out_i_d1 <= resize(accum_i / signed(factor), out_i_d1'length);
					--out_q_d1 <= resize(accum_q / signed(factor), out_q_d1'length);

					div_numer_i <= std_logic_vector(accum_i + shift_left(in_i, to_integer(in_shift))) ;
					div_numer_q <= std_logic_vector(accum_q + shift_left(in_q, to_integer(in_shift))) ;

					out_valid_d0 <= '1';

					accum_i <= (others => '0');
					accum_q <= (others => '0');
					counter := (others => '0');
				else
					accum_i <= accum_i + shift_left(in_i, to_integer(in_shift));
					accum_q <= accum_i + shift_left(in_q, to_integer(in_shift));
				end if;
			end if;
		end if;
	end process;

end architecture;
