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


  type ram_t is record
    -- common clock
      clk    : std_logic;
      -- Port A
      we_a   : std_logic;
      re_a   : std_logic;
      r_addr_a : std_logic_vector(ADDR_WIDTH-1 downto 0);
      addr_a : std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_a : std_logic_vector(ICPX_BV_LEN-1 downto 0);
      q_a    : std_logic_vector(ICPX_BV_LEN-1 downto 0);
      q_a_valid : std_logic;

      -- Port B
      we_b   : std_logic;
      re_b   : std_logic;
      addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_b : std_logic_vector(ICPX_BV_LEN-1 downto 0);
      q_b    : std_logic_vector(ICPX_BV_LEN-1 downto 0);
      q_b_valid : std_logic;
  end record;

  type fifo_mem_type is array (0 to 3) of ram_t;
  signal mem : fifo_mem_type;

  signal some_data : std_logic_vector(ICPX_BV_LEN-1 downto 0);
  signal some_data_b : std_logic_vector(ICPX_BV_LEN-1 downto 0);

  signal some_data_valid : std_logic;
  signal some_data_b_valid : std_logic;


  signal some_data_delayed : std_logic_vector(ICPX_BV_LEN-1 downto 0);

  signal read_index : natural range 0 to 3;
  type reader_t is record
  	i : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  	active : std_logic;
  end record;

  signal reader : reader_t;

begin
	clk <= not clk after 10 ns when end_sim = false else '0';

  	-- Generate a dpram block for every buffer
  	generate_rams : for i in fifo_mem_type'range generate
        U_ramfifo_ram : entity work.dp_ram_scl
          generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => ICPX_BV_LEN
          ) port map (
            clk     => clk,
            
            we_a    => mem(i).we_a,
            re_b 	=> mem(i).re_a,
            addr_a  => mem(i).r_addr_a,
            data_a  => mem(i).data_a,
            q_a     => mem(i).q_a,
            q_a_valid => mem(i).q_a_valid,

            we_b    => mem(i).we_b,
            addr_b  => mem(i).addr_b,
            data_b  => mem(i).data_b,
            q_b     => mem(i).q_b,
            q_b_valid => mem(i).q_b_valid
          ) ;


          mem(i).r_addr_a <= reader.i when reader.active = '1' else mem(i).addr_a;
    end generate ;

    some_data <= mem(read_index).q_a;
	some_data_b <= mem(read_index).q_b;
	some_data_valid <= mem(read_index).q_a_valid;
	some_data_b_valid <= mem(read_index).q_b_valid;

	delay_signal : process(some_data)
	begin
		--if rising_edge(clk) then
			some_data_delayed <= some_data;
		--end if;
	end process; 

	read_driver : process(clk)
	begin
		if rising_edge(clk) then
			if rst_n = '0' or reader.active = '0' then
				reader.i <= (others => '0');
			elsif reader.active = '1' then
				if unsigned(reader.i) = reader.i'high then
					reader.i <= (others => '0');
				else
					reader.i <= std_logic_vector( unsigned(reader.i) + 1 );
				end if;
			end if;
		end if;
	end process;

	WaveGen_Proc : process
	begin
		reader.active <= '0';
	    wait until clk = '1';
	    wait for 15 ns;
	    wait until clk = '0';
	    wait until clk = '1';
	    rst_n <= '1';

	    wait until clk = '0';
	    wait until clk = '1';


	    -- Store some data inside RAM
	    mem(0).we_a <= '1';
	    mem(0).addr_a <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
	    mem(0).data_a <= std_logic_vector(to_unsigned(16#00#, ICPX_BV_LEN));

	    mem(0).we_b <= '1';
	    mem(0).addr_b <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));
	    mem(0).data_b <= std_logic_vector(to_unsigned(16#10#, ICPX_BV_LEN));
		wait until clk = '0';
	    wait until clk = '1';

	    mem(0).we_a <= '1';
	    mem(0).addr_a <= std_logic_vector(to_unsigned(2, ADDR_WIDTH));
	    mem(0).data_a <= std_logic_vector(to_unsigned(16#20#, ICPX_BV_LEN));

	    mem(0).we_b <= '1';
	    mem(0).addr_b <= std_logic_vector(to_unsigned(3, ADDR_WIDTH));
	    mem(0).data_b <= std_logic_vector(to_unsigned(16#30#, ICPX_BV_LEN));
		wait until clk = '0';
	    wait until clk = '1';

	    mem(0).addr_a <= std_logic_vector(to_unsigned(4, ADDR_WIDTH));
	    mem(0).data_a <= std_logic_vector(to_unsigned(16#40#, ICPX_BV_LEN));

	    mem(0).we_b <= '1';
	    mem(0).addr_b <= std_logic_vector(to_unsigned(5, ADDR_WIDTH));
	    mem(0).data_b <= std_logic_vector(to_unsigned(16#50#, ICPX_BV_LEN));
		wait until clk = '0';
	    wait until clk = '1';

	    -- Fetch two data addresses simultaneously
	    --read_index <= 0;
	    mem(0).we_a <= '0';
	    --mem(0).addr_a <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
	    

	    mem(0).we_b <= '0';
	    --mem(0).addr_b <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));

	    mem(0).addr_a <= reader.i;
	    reader.active <= '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';

	    wait until clk = '0';
	    wait until clk = '1';


	    end_sim <= true;

	    
	end process;

end architecture;