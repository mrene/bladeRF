-- This components acts as a write-only RAM block until the `in_commit` signal is high.
-- The data is delivered one value at a time on the output clock

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.fft_len.all;
use work.icpx.all;
use work.all;


entity dpram_fifo is
	generic (
		constant FIFO_DEPTH	: positive := 2;
		constant ADDR_WIDTH	: positive := 8
	);
	port ( 
		clk		  : in  std_logic;
		rst		  : in  std_logic;

		-- Ram port A
		in_valid_a    : in std_logic;
		in_data_a  	  : in icpx_number;
		in_addr_a     : in std_logic_vector(ADDR_WIDTH - 1 downto 0);

		-- Ram port B
		in_valid_b    : in std_logic;
		in_data_b  	  : in icpx_number;
		in_addr_b     : in std_logic_vector(ADDR_WIDTH - 1 downto 0);

		-- Set HIGH when writing the last value (commits to the fifo)
		in_commit	  : in std_logic;

		read_enable	: in  std_logic;
		out_data_a	: out icpx_number;
		out_data_b	: out icpx_number;
		out_valid	: out std_logic;
		 -- Indicates this is the first sample of an FFT
		out_new		: out std_logic;


		empty	: out std_logic;
		full	: out std_logic
	);


end dpram_fifo;

architecture rtl of dpram_fifo is
	type ram_t is record
		clk : std_logic;
	    -- Port A
	    we_a   : std_logic;
	    addr_a : std_logic_vector(ADDR_WIDTH-1 downto 0);
	    data_a : std_logic_vector(ICPX_BV_LEN-1 downto 0);
	    q_a    : std_logic_vector(ICPX_BV_LEN-1 downto 0);

	    -- Port B
	    we_b   : std_logic;
	    addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0);
	    data_b : std_logic_vector(ICPX_BV_LEN-1 downto 0);
	    q_b    : std_logic_vector(ICPX_BV_LEN-1 downto 0);

	    -- Flags
	    reading : std_logic;
	    writing : std_logic;
	end record;

	type fifo_mem_type is array (0 to FIFO_DEPTH - 1) of ram_t;	
	signal mem : fifo_mem_type;


  	signal internal_valid : std_logic;
  	signal internal_new : std_logic;
  	signal internal_new_delayed : std_logic;

	signal debug_tail_index : natural range 0 to (2 ** ADDR_WIDTH) - 1; --std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal debug_head : natural range 0 to FIFO_DEPTH - 1;
	signal debug_tail : natural range 0 to FIFO_DEPTH - 1;


	signal debug_tail_delayed : natural range 0 to FIFO_DEPTH - 1;
	signal debug_tail_delayed2 : natural range 0 to FIFO_DEPTH - 1;
	signal debug_tail_index_delayed : natural range 0 to (2 ** ADDR_WIDTH) - 1; --std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin
	-- Generate a dpram block for every buffer
	generate_rams : for i in fifo_mem_type'range generate
        U_ramfifo_ram : entity work.dp_ram_scl
          generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => ICPX_BV_LEN
          ) port map (
          	clk 	=> clk,
          	
          	we_a 	=> mem(i).we_a,
          	addr_a 	=> mem(i).addr_a,
          	data_a 	=> mem(i).data_a,
          	q_a 	=> mem(i).q_a,

          	we_b 	=> mem(i).we_b,
          	addr_b 	=> mem(i).addr_b,
          	data_b 	=> mem(i).data_b,
          	q_b 	=> mem(i).q_b
          ) ;


          -- Connect the RAM component directly to the input pins if they are active
          mem(i).we_a   <= 	in_valid_a when mem(i).writing = '1' else '0';


          mem(i).addr_a <=	in_addr_a 			when mem(i).writing = '1' else
          					std_logic_vector(to_unsigned(debug_tail_index_delayed, ADDR_WIDTH)) when mem(i).reading = '1' else
          					std_logic_vector(to_unsigned(2 ** ADDR_WIDTH - 2, ADDR_WIDTH));
          					
          mem(i).data_a <= icpx2stlv(in_data_a) when mem(i).writing = '1' else (others => '0');

          mem(i).we_b   <= in_valid_b when mem(i).writing = '1' else  '0';

          mem(i).addr_b <=	in_addr_b 		 when mem(i).writing = '1' else
          					std_logic_vector(to_unsigned(debug_tail_index_delayed+1, ADDR_WIDTH)) when mem(i).reading = '1' else
          					(others => '1');
          					
          mem(i).data_b <= icpx2stlv(in_data_b) when mem(i).writing = '1' else (others => '0');

          mem(i).writing <= '1' when debug_head = i else '0';
          mem(i).reading <= '1' when debug_tail = i and debug_head /=i else '0';
    end generate ;

	-- Map output data directly from tail ram's A port
	out_data_a <= stlv2icpx(mem(debug_tail_delayed2).q_a);
	out_data_b <= stlv2icpx(mem(debug_tail_delayed2).q_b);

	delay_output_signals : process(clk, rst)
	begin
		if rst = '0' then
			out_new <= '0';
			out_valid <= '0';
		elsif rising_edge(clk) then
			debug_tail_index_delayed <= debug_tail_index;
			debug_tail_delayed <= debug_tail;
			debug_tail_delayed2 <= debug_tail_delayed;
			out_valid <= internal_valid;

			internal_new_delayed <= internal_new;
			out_new <= internal_new_delayed;
		end if;
	end process; 

	---- Memory Pointer Process
	fifo_proc : process (clk)
		-- Indexes
		variable head : natural range 0 to FIFO_DEPTH - 1;
		variable tail : natural range 0 to FIFO_DEPTH - 1;
		-- Read position
		variable tail_index : natural range 0 to (2 ** ADDR_WIDTH) - 1;
		variable looped : boolean;
	begin
		if (rising_edge(clk)) then
			if rst = '0' then
				head := 0;
				tail := 0;
				looped := false;
				full  <= '0';
				empty <= '1';
				internal_valid <= '0';
				internal_new <= '0';

				debug_head <= 0;
				debug_tail <= 0;
			else
				internal_valid <= '0';
				internal_new <= '0';

				-- Move the write head once the buffer is done
				if (in_commit = '1') then
					if ((looped = false) or (head /= tail)) then
						if (head = FIFO_DEPTH - 1) then
							head := 0;
							looped := true;
						else
							head := head + 1;
						end if;
					end if;
				end if;

				if (read_enable = '1') then
					if ((looped = true) or (head /= tail)) then
						internal_valid <= '1';
						
						if (tail_index = 0) then 
							tail_index := tail_index + 2;
						elsif (tail_index = (2 ** ADDR_WIDTH) - 2) then
							-- Move to next element
							if (tail = FIFO_DEPTH - 1) then
								tail := 0;
								looped := false;
							else
								tail := tail + 1;
							end if;

							internal_new <= '1';
							tail_index := 0;
						else
							tail_index := tail_index + 2;
						end if;
					end if;
				end if;
				
				-- Update Empty and Full flags
				if (head = tail) then
					if looped then
						full <= '1';
					else
						empty <= '1';
					end if;
				else
					empty	<= '0';
					full	<= '0';
				end if;

				debug_tail_index <= tail_index;
				debug_head <= head;
				debug_tail <= tail;
			end if;
		end if;
	end process;

end rtl;
