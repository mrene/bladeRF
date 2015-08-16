library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.math_complex.all;
library std;
use std.textio.all;
library work;
use work.fft_len.all;
use work.icpx.all;
use work.fft_support_pkg.all;

-------------------------------------------------------------------------------

entity ram_tb is

end ram_tb;

-------------------------------------------------------------------------------

architecture wtf of ram_tb is
  constant ADDR_WIDTH : positive := 4;

  -- component ports
  signal rst_n : std_logic := '0';

  -- clock
  signal clk : std_logic := '1';

  signal end_sim : boolean := false;

  type ramfifo_t is record
	-- Ram port A
	in_valid_a    : std_logic;
	in_data_a  	  : icpx_number;
	in_addr_a     : std_logic_vector(ADDR_WIDTH - 1 downto 0);

	-- Ram port B
	in_valid_b    : std_logic;
	in_data_b  	  : icpx_number;
	in_addr_b     : std_logic_vector(ADDR_WIDTH - 1 downto 0);

	in_commit	  : std_logic;	-- Set HIGH when writing the last value (commits to the fifo)

	--read_enable	: std_logic;
	out_data_a	: icpx_number;
	out_data_b	: icpx_number;
	out_valid	: std_logic;
	out_sob		: std_logic; -- Indicates this is the first sample


	read_enable	: std_logic;
	empty	: std_logic;
	full	: std_logic;
  end record;

  signal ramfifo : ramfifo_t;

begin
	clk <= not clk after 10 ns when end_sim = false else '0';

  	-- Generate a dpram block for every buffer
    U_ramfifo : entity work.dpram_fifo
      generic map (
      	NUM_FRAMES => 4,
        ADDR_WIDTH => ADDR_WIDTH
      ) port map (
        clk     => clk,
        rst_n 	=> rst_n,

        in_valid_a => ramfifo.in_valid_a,
        in_data_a => ramfifo.in_data_a,
        in_addr_a => ramfifo.in_addr_a,

        in_valid_b => ramfifo.in_valid_b,
        in_data_b => ramfifo.in_data_b,
        in_addr_b => ramfifo.in_addr_b,

        in_commit => ramfifo.in_commit,

        read_enable => ramfifo.read_enable,

        out_data_a => ramfifo.out_data_a,
        out_data_b => ramfifo.out_data_b,
        out_valid => ramfifo.out_valid,
        out_sob => ramfifo.out_sob,

        empty => ramfifo.empty,
        full => ramfifo.full
      ) ;

	WaveGen_Proc : process
	begin
	    wait until clk = '1';
	    wait for 15 ns;
	    wait until clk = '0';
	    wait until clk = '1';

	    rst_n <= '1';
	    ramfifo.read_enable <= '1';

	    -- Generate some input data
	    for i in 0 to 7 loop
			wait until clk = '0';
		    wait until clk = '1';

		    ramfifo.in_valid_a <= '1';
		    ramfifo.in_addr_a <= std_logic_vector(to_unsigned(2 * i, ADDR_WIDTH));
		    ramfifo.in_data_a <= stlv2icpx(std_logic_vector(to_unsigned(16#1000# + (2 * i), ICPX_BV_LEN)));

		    ramfifo.in_valid_b <= '1';
		    ramfifo.in_addr_b <= std_logic_vector(to_unsigned((2 * i) + 1, ADDR_WIDTH));
		    ramfifo.in_data_b <= stlv2icpx(std_logic_vector(to_unsigned(16#1000# + (2 * i) + 1, ICPX_BV_LEN)));

			wait until clk = '0';
		    wait until clk = '1';

		    ramfifo.in_valid_a <= '0';
		    ramfifo.in_data_a <= icpx_zero;

		    ramfifo.in_valid_b <= '0';
		    ramfifo.in_data_b <= icpx_zero;

	    end loop;

	    ramfifo.in_commit <= '1';

		wait until clk = '0';
	    wait until clk = '1';

	    ramfifo.in_commit <= '0';

		-- Generate some input data
	    for i in 0 to 7 loop
			wait until clk = '0';
		    wait until clk = '1';

		    ramfifo.in_valid_a <= '1';
		    ramfifo.in_addr_a <= std_logic_vector(to_unsigned(2 * i, ADDR_WIDTH));
		    ramfifo.in_data_a <= stlv2icpx(std_logic_vector(to_unsigned(16#2000# + (2 * i), ICPX_BV_LEN)));

		    ramfifo.in_valid_b <= '1';
		    ramfifo.in_addr_b <= std_logic_vector(to_unsigned((2 * i) + 1, ADDR_WIDTH));
		    ramfifo.in_data_b <= stlv2icpx(std_logic_vector(to_unsigned(16#2000# + (2 * i) + 1, ICPX_BV_LEN)));


			wait until clk = '0';
		    wait until clk = '1';

		    ramfifo.in_valid_a <= '0';
		    ramfifo.in_data_a <= icpx_zero;
		    
		    ramfifo.in_valid_b <= '0';
		    ramfifo.in_data_b <= icpx_zero;

	    end loop;

	    ramfifo.in_commit <= '1';

		wait until clk = '0';
	    wait until clk = '1';

	    ramfifo.in_commit <= '0';

		-- Generate some input data
	    for i in 0 to 7 loop
			wait until clk = '0';
		    wait until clk = '1';

		    ramfifo.in_valid_a <= '1';
		    ramfifo.in_addr_a <= std_logic_vector(to_unsigned(2 * i, ADDR_WIDTH));
		    ramfifo.in_data_a <= stlv2icpx(std_logic_vector(to_unsigned(16#3000# + (2 * i), ICPX_BV_LEN)));

		    ramfifo.in_valid_b <= '1';
		    ramfifo.in_addr_b <= std_logic_vector(to_unsigned((2 * i) + 1, ADDR_WIDTH));
		    ramfifo.in_data_b <= stlv2icpx(std_logic_vector(to_unsigned(16#3000# + (2 * i) + 1, ICPX_BV_LEN)));


			wait until clk = '0';
		    wait until clk = '1';

		    ramfifo.in_valid_a <= '0';
		    ramfifo.in_data_a <= icpx_zero;
		    
		    ramfifo.in_valid_b <= '0';
		    ramfifo.in_data_b <= icpx_zero;
	    end loop;

	    ramfifo.in_commit <= '1';


	    ramfifo.in_valid_a <= '0';
	    ramfifo.in_valid_b <= '0';

		wait until clk = '0';
	    wait until clk = '1';

	    ramfifo.in_commit <= '0';


	    for i in 0 to 50 loop
			wait until clk = '0';
		    wait until clk = '1';
	   end loop;

	   end_sim <= true;

	    
	end process;


	stdout : process (clk) 
	begin
		if rising_edge(clk) then
			if ramfifo.out_valid = '1' then
				--report integer'image(to_integer(ramfifo.out_data_a.re));
				report integer'image(to_integer(ramfifo.out_data_a.im));

				--report integer'image(to_integer(ramfifo.out_data_b.re));
				report integer'image(to_integer(ramfifo.out_data_b.im));
			end if;
		end if;
	end process;


end architecture;