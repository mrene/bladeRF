-- This components acts as a write-only RAM block until the `in_commit` signal is high.
-- The data is delivered one value at a time on the output clock

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_len.all;
use work.icpx.all;
use work.all;


entity dpram_fifo is
    generic (
        constant NUM_FRAMES : positive := 2;
        constant ADDR_WIDTH : positive := 8
    );
    port ( 
        clk       : in  std_logic;
        rst_n     : in  std_logic;

        -- Ram port A
        in_valid_a    : in std_logic;
        in_data_a     : in icpx_number;
        in_addr_a     : in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        -- Ram port B
        in_valid_b    : in std_logic;
        in_data_b     : in icpx_number;
        in_addr_b     : in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        -- Set HIGH when writing the last value (commits to the fifo)
        in_commit     : in std_logic;

        read_enable : in  std_logic;
        out_data_a  : out icpx_number;
        out_data_b  : out icpx_number;
        out_valid   : out std_logic;
         -- Indicates this is the first sample of an FFT
        out_sob     : out std_logic;


        empty   : out std_logic;
        full    : out std_logic
    );


end dpram_fifo;

architecture rtl of dpram_fifo is
    type ram_t is record
        clk : std_logic;
        -- Port A
        we_a   : std_logic;
        re_a   : std_logic;
        addr_a : std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_a : icpx_number;
        q_a    : icpx_number;
        q_a_valid : std_logic;

        -- Port B
        we_b   : std_logic;
        re_b   : std_logic;
        addr_b : std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_b : icpx_number;
        q_b    : icpx_number;
        q_b_valid : std_logic;

        -- Flags
        reading : std_logic;
        writing : std_logic;
    end record;

    type fifo_mem_type is array (0 to NUM_FRAMES - 1) of ram_t; 
    signal mem : fifo_mem_type;


    signal internal_new : std_logic;
    signal internal_new_delayed : std_logic;

    signal debug_tail_index : natural range 0 to (2 ** ADDR_WIDTH) - 1; --std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal debug_head : natural range 0 to NUM_FRAMES - 1;
    signal debug_tail : natural range 0 to NUM_FRAMES - 1;


    signal debug_tail_delayed : natural range 0 to NUM_FRAMES - 1;
    signal debug_tail_delayed2 : natural range 0 to NUM_FRAMES - 1;

    signal debug_tail_index_delayed : natural range 0 to (2 ** ADDR_WIDTH) - 1; --std_logic_vector(ADDR_WIDTH - 1 downto 0);


    signal s_full, s_empty : std_logic;

begin
    -- Generate a dpram block for every buffer
    generate_rams : for i in fifo_mem_type'range generate
        U_ramfifo_ram : entity work.dp_ram_rbw_icpx
          generic map (
            ADDR_WIDTH => ADDR_WIDTH
          ) port map (
            clk     => clk,
            
            we_a    => mem(i).we_a,
            re_a    => mem(i).re_a,
            addr_a  => mem(i).addr_a,
            data_a  => mem(i).data_a,
            q_a     => mem(i).q_a,
            q_a_valid => mem(i).q_a_valid,

            we_b    => mem(i).we_b,
            re_b    => mem(i).re_b,
            addr_b  => mem(i).addr_b,
            data_b  => mem(i).data_b,
            q_b     => mem(i).q_b,
            q_b_valid => mem(i).q_b_valid
          ) ;


          -- Connect the RAM component directly to the input pins if they are active
          mem(i).we_a   <=  in_valid_a when mem(i).writing = '1' else '0';


          mem(i).addr_a <=  in_addr_a when mem(i).writing = '1' else
                            std_logic_vector(to_unsigned(debug_tail_index, ADDR_WIDTH)) when mem(i).reading = '1' else
                            std_logic_vector(to_unsigned(2 ** ADDR_WIDTH - 1, ADDR_WIDTH));
                            
          mem(i).data_a <= in_data_a when mem(i).writing = '1' else icpx_zero;

          mem(i).we_b   <= in_valid_b when mem(i).writing = '1' else  '0';

          mem(i).addr_b <=  in_addr_b when mem(i).writing = '1' else
                            std_logic_vector(to_unsigned(debug_tail_index+1, ADDR_WIDTH)) when mem(i).reading = '1' else
                            (others => '1');
                            
          mem(i).data_b <= in_data_b when mem(i).writing = '1' else icpx_zero;

          mem(i).writing <= '1' when debug_head = i else '0';
          mem(i).reading <= '1' when s_empty = '0' and ((debug_tail_delayed = i) or (debug_tail = i)) else '0';

          mem(i).re_a <= mem(i).reading;
          mem(i).re_b <= '0'; --mem(i).reading;
    end generate ;

    -- Map output data directly from tail ram's A port
    out_data_a <= mem(debug_tail_delayed).q_a when mem(debug_tail_delayed).q_a_valid = '1' else
                  mem(debug_tail).q_a when mem(debug_tail).q_a_valid = '1' else
                  icpx_zero;

    --out_data_b <= mem(debug_tail_delayed).q_b when mem(debug_tail_delayed).q_b_valid = '1' else
    --              mem(debug_tail).q_b  when mem(debug_tail).q_b_valid = '1' else
    --              icpx_zero;

    out_data_b <= icpx_zero;

    out_valid <= '1' when mem(debug_tail_delayed).q_a_valid = '1' else
                 '1' when mem(debug_tail).q_a_valid = '1' else
                 '0';

    full <= s_full;
    empty <= s_empty;


    delay_output_signals : process(clk, rst_n)
    begin
        if rst_n = '0' then
            out_sob <= '0';
        elsif rising_edge(clk) then
            debug_tail_index_delayed <= debug_tail_index;

            debug_tail_delayed <= debug_tail;
            debug_tail_delayed2 <= debug_tail_delayed;

            internal_new_delayed <= internal_new;
            out_sob <= internal_new_delayed;
        end if;
    end process; 

    ---- Memory Pointer Process
    fifo_proc : process (clk, rst_n)
        -- Indexes
        variable head : natural range 0 to NUM_FRAMES - 1;
        variable tail : natural range 0 to NUM_FRAMES - 1;
        -- Read position
        variable tail_index : natural range 0 to (2 ** ADDR_WIDTH) - 1;
        variable looped : boolean;
        variable started : boolean;
    begin
        if rst_n = '0' then
            head := 0;
            tail := 0;
            looped := false;
            s_full  <= '0';
            s_empty <= '1';
            internal_new <= '0';

            debug_head <= 0;
            debug_tail <= 0;
        elsif (rising_edge(clk)) then
            internal_new <= '0';

            -- Move the write head once the buffer is done
            if (in_commit = '1') then
                if ((looped = false) or (head /= tail)) then
                    if (head = NUM_FRAMES - 1) then
                        head := 0;
                        looped := true;
                    else
                        head := head + 1;
                    end if;
                end if;
            end if;

            if (read_enable = '1') then
                if ((looped = true) or (head /= tail)) then
                    if (tail_index = 0) then 
                        if (started = true) then
                            tail_index := tail_index + 1;
                            started := false;
                        else
                            started := true;
                        end if; 
                    elsif (tail_index = (2 ** ADDR_WIDTH) - 1) then
                        -- Move to next element
                        if (tail = NUM_FRAMES - 1) then
                            tail := 0;
                            looped := false;
                        else
                            tail := tail + 1;
                        end if;

                        internal_new <= '1';
                        tail_index := 0;
                    else
                        tail_index := tail_index + 1;
                    end if;
                end if;
            end if;
            
            -- Update Empty and Full flags
            if (head = tail) then
                if looped then
                    s_full <= '1';
                else
                    s_empty <= '1';
                end if;
            else
                s_empty   <= '0';
                s_full    <= '0';
            end if;

            debug_tail_index <= tail_index;
            debug_head <= head;
            debug_tail <= tail;
        end if;
    end process;

end rtl;
