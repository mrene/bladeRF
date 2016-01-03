library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

library work;
    use work.util.all;

entity complex_fir_filter_tb is
end entity ;

architecture arch of complex_fir_filter_tb is

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

    type coeff_array_t is array(natural range <>) of std_logic_vector(31 downto 0);
    constant coeff : coeff_array_t := (
        x"ffea0000",
        x"0005ffef",
        x"000c0008",
        x"fff90005",
        x"00000000",
        x"fff00000",
        x"000cffd9",
        x"003f002e",
        x"ff98004b",
        x"ffc4ff47",
        x"01130000",
        x"ff8d0162",
        x"fe78fee3",
        x"01eefe99",
        x"00e702c7",
        x"fc850000",
        x"0140fc25",
        x"03be02b8",
        x"fbd2030a",
        x"fe40fa9c",
        x"061c0000",
        x"fe010627",
        x"fa8dfc0a",
        x"0596fbf1",
        x"0226069e",
        x"f9190000",
        x"0215f998",
        x"053c03cd",
        x"fb0f0397",
        x"fe40fa9c",
        x"052b0000",
        x"fe930466",
        x"fcb8fd9e",
        x"02d1fdf4",
        x"00e702c7",
        x"fd9d0000",
        x"0096fe33",
        x"012d00db",
        x"ff2100a2",
        x"ffc4ff47",
        x"00810000",
        x"ffe8004a",
        x"ffdfffe8",
        x"000dfff7",
        x"00000000",
        x"00090000",
        x"fffc000e",
        x"fff1fff5",
        x"0011fff3"
    );
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


    U_complex_fir_filter : entity work.complex_fir_filter
        generic map(
            NUM_TAPS => 60
        )
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
		variable ts : unsigned(63 downto 0) := (others =>'0') ;
        variable reg : std_logic_vector(31 downto 0);
    begin

        reset <= '1' ;
        nop( clock, 5 ) ;

        reset <= '0' ;
        nop( clock, 5 ) ;

        -- Write coefficients
        for i in coeff'range loop
            mm_write(clock, avs_config_address, avs_config_writedata, avs_config_write, to_unsigned(1 + i, 8), unsigned(coeff(i))) ;
        end loop;

        -- Enable module
        reg(31 downto 24) := std_logic_vector(to_unsigned(12, 8));
        reg(0) := '1';
        mm_write(clock, avs_config_address, avs_config_writedata, avs_config_write, to_unsigned(0, 8), unsigned(reg)) ;

        -- Make sure we can read the same thing
        --ts := to_unsigned(0, ts'length);

        --mm_read(clock, avs_config_address, avs_config_readdata, avs_config_read, to_unsigned(0, 8), ts(63 downto 32));

        -- Start pushing samples
        reader_request <= '1';

        nop (clock, 1000000) ;

    end process;

end architecture;


