library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

library nuand;
    use nuand.util.all;

entity decimator_controller_tb is
end entity ;

architecture arch of decimator_controller_tb is

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

    signal reader_data    : std_logic_vector(31 downto 0) := (others => '0');
    signal reader_valid   : std_logic := '0';
    signal reader_request : std_logic := '0';

    signal writer_data    : std_logic_vector(31 downto 0) := (others => '0');
    signal writer_valid   : std_logic := '0';

	-- Avalon-ST Sink (Input)
    signal asi_in_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal asi_in_valid : std_logic := '0';

    -- Avalon-ST Source (Output)
    signal aso_out_data          : std_logic_vector(31 downto 0);
    signal aso_out_valid         : std_logic; 


    -- Avalon-MM Slave
    signal avs_config_address       :  std_logic_vector(7 downto 0);
    signal avs_config_read          :  std_logic := '0';
    signal avs_config_readdata      : std_logic_vector(31 downto 0);
    signal avs_config_write         :  std_logic := '0';
    signal avs_config_writedata     :  std_logic_vector(31 downto 0);
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

            data_request => reader_request,
            data => reader_data,
            data_valid => reader_valid
        );

    U_file_writer : entity work.data_writer
    	generic map(
    		FILENAME => "output.dat",
    		DATA_WIDTH => 32
    	)
    	port map(
    		reset => reset,
    		clock => clock,

    		data 	   => writer_data,
    		data_valid => writer_valid
    	);


    U_decimator_controller : entity work.decimator_controller
        port map(
            clock => clock,
            reset => reset,

            asi_in_data  => asi_in_data,
            asi_in_valid => asi_in_valid,

            aso_out_data          => aso_out_data,
            aso_out_valid         => aso_out_valid,

            avs_config_address   => avs_config_address,
            avs_config_read      => avs_config_read,
            avs_config_readdata  => avs_config_readdata,
            avs_config_write     => avs_config_write,
            avs_config_writedata => avs_config_writedata
        );


    -- Mapping to our Avalon-ST interface
    -- I and Q are reversed because we are reading 2x 16 bit values as a single 32 bit value.
    asi_in_data(31 downto 16) <= reader_data(15 downto 0);
    asi_in_data(15 downto 0)  <= reader_data(31 downto 16);
    asi_in_valid <= reader_valid;


    -- Same logic applies to writing samples
    writer_data(31 downto 16) <= aso_out_data(15 downto 0);
    writer_data(15 downto 0)  <= aso_out_data(31 downto 16);
    writer_valid <= aso_out_valid;

    tb : process
        variable tmp : std_logic_vector(31 downto 0) := (others => '0') ;
    begin

        reset <= '1' ;
        nop( clock, 5 ) ;

        reset <= '0' ;
        nop( clock, 5 ) ;

        -- Enable module
        tmp(31) := '1';

        -- Set decimation to 2
        tmp(15 downto 0) := std_logic_vector(to_unsigned(2, 16));

        mm_write(clock, avs_config_address, avs_config_writedata, avs_config_write, to_unsigned(0, 8), unsigned(tmp)) ;

        -- Start pushing samples
        reader_request <= '1';

        nop (clock, 1000000) ;
    end process;

end architecture;


