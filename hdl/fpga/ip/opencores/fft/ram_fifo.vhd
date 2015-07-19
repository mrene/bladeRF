--- Source: http://www.deathbylogic.com/2013/07/vhdl-standard-fifo/
--- Permission for redistribution given by the author in comments


-- This components acts as a write-only RAM block until the `in_commit` signal is high.
-- The data is delivered one value at a time on the output clock

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.icpx.all;


entity dpram_fifo is
	generic (
		constant FIFO_DEPTH	: positive := 10;
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

		in_commit	  : in std_logic;	-- Set HIGH when writing the last value (commits to the fifo)

		read_enable	: in  std_logic;
		out_data	: out icpx_number;
		out_valid	: out std_logic;
		out_new		: out std_logic; -- Indicates this is the first sample


		empty	: out std_logic;
		full	: out std_logic
	);
end dpram_fifo;

architecture rtl of dpram_fifo is
	type mem_type is array ((2**ADDR_WIDTH)-1 downto 0) of icpx_number;
	type fifo_mem_type is array (0 to FIFO_DEPTH - 1) of mem_type;
	
	shared variable mem : fifo_mem_type;
begin
  
	-- Memory Pointer Process
	fifo_proc : process (clk)
		
		-- Indexes
		variable head : natural range 0 to FIFO_DEPTH - 1;
		variable tail : natural range 0 to FIFO_DEPTH - 1;
		
		variable looped : boolean;
		
		-- Read position
		variable tail_index : natural range 0 to (2 ** ADDR_WIDTH) - 1;
	
	begin
		if (rising_edge(clk)) then
			-- RAM Port A
			if (in_valid_a = '1') then
				mem(head)(conv_integer(in_addr_a)) := in_data_a;
			end if;
			
			-- RAM Port B
			if (in_valid_b = '1') then
				mem(head)(conv_integer(in_addr_b)) := in_data_b;
			end if;
			

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
			
			
			if rst = '0' then
				head := 0;
				tail := 0;
				looped := false;
				full  <= '0';
				empty <= '1';
				out_valid <= '0';
				out_new <= '0';
			else
				if (read_enable = '1') then
					if ((looped = true) or (head /= tail)) then
						-- Output data
						out_data <= mem(tail)(tail_index);
						out_valid <= '1';
						
						if (tail_index = 0) then 
							out_new	<= '1';
							tail_index := tail_index + 1;
						elsif (tail_index = (2 ** ADDR_WIDTH) - 1) then
							-- Move to next element
							if (tail = FIFO_DEPTH - 1) then
								tail := 0;
								looped := false;
							else
								tail := tail + 1;
							end if;
							tail_index := 0;
							
							out_new <= '0';
						else
							out_new <= '0';
							
							tail_index := tail_index + 1;
						end if;
					else
						out_valid <= '0';
					end if;
				else
					out_valid <= '0';
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
			end if;
		end if;
	end process;

end rtl;