library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

library nuand;
    use nuand.util.all;

entity fft_tb is
end entity ;

architecture arch of fft_tb is

	procedure mm_write(
        signal clock    :   in  std_logic ;
        signal addr     :   out std_logic_vector(7 downto 0) ;
        signal data     :   out std_logic_vector(31 downto 0) ;
        signal write    :   out std_logic ;
        	   address  :   unsigned(7 downto 0);
               value    :   unsigned(31 downto 0)
    ) is
    begin
        addr <= std_logic_vector(address) ;
        data <= std_logic_vector(value) ;
        write <= '1' ;
        wait until rising_edge(clock) ;
        write <= '0' ;
        wait until rising_edge(clock) ;
    end procedure ;


    procedure mm_read(
    	signal clock 	: in  std_logic;
    	signal addr 	: out std_logic_vector(7 downto 0);
    	signal data		: in  std_logic_vector(31 downto 0);
    	signal read     : out std_logic;
    	       address  : unsigned(7 downto 0);
    	variable result : out  unsigned(31 downto 0)
    ) is
    begin
	    wait until rising_edge(clock);
	    addr <= std_logic_vector(address) ;
	    read <= '1';
	    wait until rising_edge(clock);
	    result := unsigned(data);
	    read <= '0';
    end procedure;

	signal clock : std_logic := '0';
	signal reset : std_logic := '1';

	-- Avalon-ST Sink (Input)
    signal asi_in_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal asi_in_valid : std_logic := '0';

    -- Avalon-ST Source (FFT Output)
    signal fft_aso_out_data          : std_logic_vector(31 downto 0);
    signal fft_aso_out_valid         : std_logic; 
    signal fft_aso_out_startofpacket : std_logic;
    signal fft_aso_out_endofpacket   : std_logic;

    -- Avalon-ST Source (Output)
    signal aso_out_data          : std_logic_vector(31 downto 0);
    signal aso_out_valid         : std_logic; 


    -- Avalon-MM Slave
    signal avs_config_address       :  std_logic_vector(7 downto 0);
    signal avs_config_read          :  std_logic := '0';
    signal avs_config_readdata      : std_logic_vector(31 downto 0);
    signal avs_config_write         :  std_logic := '0';
    signal avs_config_writedata     :  std_logic_vector(31 downto 0);


    -- Avalon-MM Slave (Multiplexer)
    signal mx_avs_config_address       :  std_logic_vector(7 downto 0);
    signal mx_avs_config_read          :  std_logic := '0';
    signal mx_avs_config_readdata      : std_logic_vector(31 downto 0);
    signal mx_avs_config_write         :  std_logic := '0';
    signal mx_avs_config_writedata     :  std_logic_vector(31 downto 0);


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

    signal rx_enable : std_logic := '0';
    signal rx_processing_fifo  : fifo_t;
	signal rx_processing_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal rx_processing_valid : std_logic := '0' ;
begin
    clock <= not clock after 1 ns ;

    U_file_reader : entity work.data_reader
        generic map (
            FILENAME => "input.dat",
            DATA_WIDTH => 32
        )
        port map (
            reset => reset,
            clock => clock,

            data_request => rx_enable and not rx_processing_fifo.wfull,
            data => rx_processing_fifo.wdata,
            data_valid => rx_processing_fifo.wreq
        );

    U_file_writer : entity work.data_writer
    	generic map(
    		FILENAME => "output.dat",
    		DATA_WIDTH => 32
    	)
    	port map(
    		reset => reset,
    		clock => clock,

    		data 	   => fft_aso_out_data,
    		data_valid => fft_aso_out_valid
    	);

    U_processing_fifo : entity work.multiplexer_fifo
      port map (
        aclr                => rx_processing_fifo.aclr,
        data                => rx_processing_fifo.wdata,
        rdclk               => rx_processing_fifo.rclock,
        rdreq               => rx_processing_fifo.rreq,
        wrclk               => rx_processing_fifo.wclock,
        wrreq               => rx_processing_fifo.wreq,
        q                   => rx_processing_fifo.rdata,
        rdempty             => rx_processing_fifo.rempty,
        rdfull              => rx_processing_fifo.rfull,
        rdusedw             => rx_processing_fifo.rused,
        wrempty             => rx_processing_fifo.wempty,
        wrfull              => rx_processing_fifo.wfull,
        wrusedw             => rx_processing_fifo.wused
      );


    rx_processing_fifo.aclr <= reset ;
    rx_processing_fifo.wclock <= clock ;

    U_sampling_bridge : entity work.sampling_bridge
      port map (
        clock => clock,
        reset => reset,

        data => rx_processing_data,
        valid => rx_processing_valid,

        rclock => rx_processing_fifo.rclock,
        rdata  => rx_processing_fifo.rdata,
        rreq   => rx_processing_fifo.rreq,
        rempty => rx_processing_fifo.rempty,
        rfull  => rx_processing_fifo.rfull,
        rused  => rx_processing_fifo.rused
     );


    U_fft : entity work.fft
    	generic map(
    		ADDR_WIDTH => 8,
    		DATA_WIDTH => 32
		)
    	port map(
    		clock => clock,
    		reset => reset,

    		asi_in_data  => asi_in_data,
    		asi_in_valid => asi_in_valid,

    		aso_out_data 		  => fft_aso_out_data,
    		aso_out_valid 		  => fft_aso_out_valid,
    		aso_out_startofpacket => fft_aso_out_startofpacket,
    		aso_out_endofpacket   => fft_aso_out_endofpacket,

    		avs_config_address 	 => avs_config_address,
    		avs_config_read 	 => avs_config_read,
    		avs_config_readdata  => avs_config_readdata,
    		avs_config_write 	 => avs_config_write,
    		avs_config_writedata => avs_config_writedata
    	);



    U_multiplexer_controller : entity work.multiplexer_controller
        port map(
            clock => clock,
            reset => reset,

            asi_in0_data => asi_in_data,
            asi_in0_valid => asi_in_valid,
            asi_in0_startofpacket => '0',
            asi_in0_endofpacket => '0',

            asi_in1_data => fft_aso_out_data,
            asi_in1_valid => fft_aso_out_valid,
            asi_in1_startofpacket => fft_aso_out_startofpacket,
            asi_in_1_endofpacket => fft_aso_out_endofpacket,

            aso_out_data  => aso_out_data,
            aso_out_valid => aso_out_valid
        )


    -- Mapping to our Avalon-ST interface
    asi_in_data(31 downto 16) <= rx_processing_data(15 downto 0);
    asi_in_data(15 downto 0) <= rx_processing_data(31 downto 16);
    asi_in_valid <= rx_processing_valid;

    tb : process
		variable ts : unsigned(63 downto 0) := (others =>'0') ;
    begin

        reset <= '1' ;
        nop( clock, 5 ) ;

        reset <= '0' ;
        nop( clock, 5 ) ;

        -- Set a countdown of 16384 samples
        ts := to_unsigned(16384, ts'length);
        mm_write(clock, avs_config_address, avs_config_writedata, avs_config_write, to_unsigned(1, 8), ts(63 downto 32)) ;
        mm_write(clock, avs_config_address, avs_config_writedata, avs_config_write, to_unsigned(2, 8), ts(31 downto 0)) ;

        -- Enable module
        mm_write(clock, avs_config_address, avs_config_writedata, avs_config_write, to_unsigned(0, 8), to_unsigned(1, 32)) ;

        -- Enable output streams
        mm_write(clock, mx_avs_config_address, mx_avs_config_writedata, mx_avs_config_write, to_unsigned(0,8), x"ff") ;

        -- Make sure we can read the same thing
        ts := to_unsigned(0, ts'length);

        mm_read(clock, avs_config_address, avs_config_readdata, avs_config_read, to_unsigned(1, 8), ts(63 downto 32));
        mm_read(clock, avs_config_address, avs_config_readdata, avs_config_read, to_unsigned(1, 8), ts(31 downto 0));

        -- TODO: Asset read value

        -- Start pushing samples
        rx_enable <= '1';

        nop (clock, 1000000) ;

    end process;

end architecture;


