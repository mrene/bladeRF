library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use ieee.math_complex.all;

library std;
    use std.env.all;

library nuand;
    use nuand.util.all;
    use nuand.multiplexer_p.all;
--library work;


entity multiplexer_tb is
end entity;

architecture arch of multiplexer_tb is
	signal clock : std_logic := '1';
	signal reset : std_logic := '1';

	signal siggen_a_i, siggen_a_q, siggen_b_i, siggen_b_q : signed(15 downto 0);
	signal siggen_a_valid, siggen_b_valid : std_logic;

	signal data_a, data_b : std_logic_vector(31 downto 0);

	signal mux_out : std_logic_vector(31 downto 0);
	signal mux_valid : std_logic;
begin
	clock <= not clock after 1 ns;

	U_siggen_a : entity work.signal_generator
		port map (
			clock => clock,
			reset => reset,
			enable => '1',
			mode => '0',
			sample_i => siggen_a_i,
			sample_q => siggen_a_q,
			sample_valid => siggen_a_valid
		);

	U_siggen_b : entity work.signal_generator
		port map (
			clock => clock,
			reset => reset,
			enable => '1',
			mode => '1',
			sample_i => siggen_b_i,
			sample_q => siggen_b_q,
			sample_valid => siggen_b_valid
		);

	U_muxer : entity work.multiplexer
		generic map (
			PACKET_LEN => 256,
			NUM_STREAMS => 2
		)
		port map (
			clock => clock,
			reset => reset,

			inputs(0).clock => clock,
			inputs(0).data => data_a,
			inputs(0).valid => siggen_a_valid,
			inputs(0).enabled => '1',
			inputs(0).startofpacket => '0',
			inputs(0).endofpacket => '0',

			inputs(1).clock => clock,
			inputs(1).data => data_b,
			inputs(1).valid => siggen_b_valid,
			inputs(1).enabled => '1',
			inputs(1).startofpacket => '0',
			inputs(1).endofpacket => '0',

			data => mux_out,
			valid => mux_valid
		);

	data_a <= std_logic_vector(siggen_a_i & siggen_a_q);
	data_b <= std_logic_vector(siggen_b_i & siggen_b_q);

	main : process
	begin
		nop(clock, 10);
		reset <= '0';
		nop(clock,10000);
	end process;
end arch;
