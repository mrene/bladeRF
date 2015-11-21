---
--- Multiplexer / Packetizer
--- 

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;

package multiplexer is
    type stream_t is record
        -- Avalon-ST interface
        clk   : std_logic ;
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
    use work.multiplexer.all;

entity multiplexer is
    generic(
        NUM_STREAMS : positive := 2 ;
        PACKET_LEN  : positive := 256
    );
    port (
        -- Output clock domain
        clk : in std_logic ;
        reset : in std_logic ;
        data : out std_logic_vector(31 downto 0) ;
        valid : out std_logic ;

        inputs : in stream_array_t(NUM_STREAMS-1 downto 0)
    );
end entity ;

architecture rtl of multiplexer is

    type fifo_t is record
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

    type state_t is ( ST_IDLE, ST_HEADER, ST_DATA ) ;
    type fifo_array_t is array (inputs'range) of fifo_t ;
    
    signal fifos         : fifo_array_t ;
    signal stream_id     : natural range inputs'range ;
    signal state         : state_t ;
    signal data_length   : unsigned(15 downto 0) ;
    signal internal_data : std_logic_vector(31 downto 0) ;

begin
    -- Wire the inputs to their respective FIFOs
    input_map : for i in inputs'range generate
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

        fifos(i).wclock <= inputs(i).clk ;
        fifos(i).wdata <= inputs(i).data ;
        fifos(i).wreq <= inputs(i).valid and inputs(i).enabled ;

        fifos(i).rclock <= clk ;
        fifos(i).aclr <= reset or not inputs(i).enabled ;        

        --flaghandler : process(inputs(i).clk, rst)
        --begin
        --   if reset = '1' then

        --   elsif rising_edge(inputs(i).clk) then

        --   end if;
        --end

    end generate;

    data <= fifos(stream_id).rdata when state = ST_DATA else internal_data;

    packetizer : process(clk, reset)
    begin
        if reset = '1' then
            state <= ST_IDLE;
            stream_id <= 0;
            valid <= '0';
        elsif rising_edge(clk) then
            case state is
                when ST_IDLE =>
                    -- Increment the stream id to evaluate the next input
                    if stream_id = NUM_STREAMS-1 then
                        stream_id <= 0;
                    else 
                        stream_id <= stream_id + 1;
                    end if;

                    -- Switch to the header state if this stream contains pending data
                    if inputs(stream_id).enabled = '1' and fifos(stream_id).rempty = '0' then
                        state <= ST_HEADER;
                    end if;

                when ST_HEADER =>
                    if unsigned(fifos(stream_id).rused) <= PACKET_LEN/4 then
                        data_length <= resize(unsigned(fifos(stream_id).rused), data_length'length);
                    else
                        data_length <= to_unsigned(PACKET_LEN/4, data_length'length);
                    end if;

                    internal_data <= std_logic_vector(resize(data_length*4, 16)) & std_logic_vector(to_unsigned(stream_id, 8)) & x"FF"; -- TODO: Set flags for startofpacket/endofpacket
                    valid <= '1';

                    -- Request read on this fifo
                    fifos(stream_id).rreq <= '1';
                    valid <= '1';
                    state <= ST_DATA;

                when ST_DATA =>
                    data_length <= data_length - 1;
                    if data_length = 0 then
                        fifos(stream_id).rreq <= '0';
                        valid <= '0';
                        state <= ST_IDLE ;
                    end if;

            end case;
        end if;
    end process;

end rtl;
