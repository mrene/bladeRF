---
--- Multiplexer / Packetizer
--- 

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;

package multiplexer_p is
    type stream_t is record
        -- Avalon-ST interface
        clock : std_logic ;
        data  :  std_logic_vector(31 downto 0) ;
        valid :  std_logic ;
        startofpacket : std_logic ;
        endofpacket   : std_logic ;

        -- Configuration
        enabled : std_logic ;
    end record ;
    type stream_array_t is array (natural range <>) of stream_t;

end package;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;
    use work.multiplexer_p.all;

entity multiplexer is
    generic(
        NUM_STREAMS : positive := 2 ;
        PACKET_LEN  : positive := 256
    );
    port (
        -- Output clock domain
        clock : in std_logic ;
        reset : in std_logic ;
        data : out std_logic_vector(31 downto 0) ;
        valid : out std_logic ;

        inputs : in stream_array_t(NUM_STREAMS-1 downto 0)
    );
end entity ;

architecture rtl of multiplexer is

    type mux_fifo_t is record
        aclr    :   std_logic ;

        wclock  :   std_logic ;
        wdata   :   std_logic_vector(31 downto 0) ;
        wreq    :   std_logic ;
        wempty  :   std_logic ;
        wfull   :   std_logic ;
        wused   :   std_logic_vector(11 downto 0) ;

        rclock  :   std_logic ;
        rdata   :   std_logic_vector(31 downto 0) ;
        rreq    :   std_logic ;
        rempty  :   std_logic ;
        rfull   :   std_logic ;
        rused   :   std_logic_vector(11 downto 0) ;

    end record ;

    type state_t is ( ST_IDLE, ST_CHECK, ST_HEADER, ST_DATA ) ;
    type fifo_array_t is array (inputs'range) of mux_fifo_t ;
    
    signal fifos         : fifo_array_t ;
    signal current_fifo  : mux_fifo_t ;
    signal current_rreq  : std_logic := '0';
    signal stream_id     : natural range inputs'range ;
    signal state         : state_t ;
    signal data_length   : unsigned(15 downto 0) ;
    signal internal_data : std_logic_vector(31 downto 0) ;

begin
    -- Wire the inputs to their respective FIFOs
    input_stage : for i in inputs'range generate
        U_fifo : entity work.multiplexer_fifo
          port map (
            aclr                => fifos(i).aclr,
            data                => fifos(i).wdata,
            rdclk               => fifos(i).rclock,
            rdreq               => fifos(i).rreq,
            wrclk               => fifos(i).wclock,
            wrreq               => fifos(i).wreq,
            q                   => fifos(i).rdata,
            rdempty             => fifos(i).rempty,
            rdfull              => fifos(i).rfull,
            rdusedw             => fifos(i).rused,
            wrempty             => fifos(i).wempty,
            wrfull              => fifos(i).wfull,
            wrusedw             => fifos(i).wused
          );

        fifos(i).wclock <= inputs(i).clock ;
        fifos(i).wdata <= inputs(i).data ;
        fifos(i).wreq <= inputs(i).valid;

        fifos(i).rclock <= clock ;
        fifos(i).aclr <= '0';
        fifos(i).rreq <= current_rreq when stream_id = i else '0';

        --flaghandler : process(inputs(i).clock, rst)
        --begin
        --   if reset = '1' then

        --   elsif rising_edge(inputs(i).clock) then

        --   end if;
        --end

    end generate;

    current_fifo <= fifos(stream_id);
    data <= current_fifo.rdata when state = ST_DATA else internal_data;

    packetizer : process(clock, reset)
    begin
        if reset = '1' then
            state <= ST_IDLE;
            stream_id <= 0;
            valid <= '0';
            current_rreq <= '0';
        elsif rising_edge(clock) then
            case state is
                when ST_IDLE =>
                    -- Increment the stream id to evaluate the next input
                    if stream_id = NUM_STREAMS-1 then
                        stream_id <= 0;
                    else 
                        stream_id <= stream_id + 1;
                    end if;

                    state <= ST_CHECK;

                when ST_CHECK =>
                    -- Switch to the header state if this stream contains pending data
                    if inputs(stream_id).enabled = '1' 
                        and current_fifo.rempty = '0' 
                        and unsigned(current_fifo.rused) >= PACKET_LEN/4 then
                            data_length <= to_unsigned(PACKET_LEN/4, data_length'length);                        
                            internal_data <= std_logic_vector(to_unsigned(PACKET_LEN, 16)) & std_logic_vector(to_unsigned(stream_id, 8)) & x"FF"; -- TODO: Set flags for startofpacket/endofpacket
                            valid <= '1';
                            state <= ST_HEADER;
                    else
                        state <= ST_CHECK;
                    end if;

                when ST_HEADER =>    
                    state <= ST_DATA;
                    current_rreq <= '1';

                when ST_DATA =>
                    data_length <= data_length - 1;
                    if data_length = 0 then
                        current_rreq <= '0';
                        valid <= '0';
                        state <= ST_IDLE ;
                    end if;

            end case;
        end if;
    end process;

end rtl;
