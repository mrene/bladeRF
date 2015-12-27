--- Bridges data from the sample domain to the processing domain
--- See: sampling_bridge.vhd for the other side.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;

entity processing_bridge is 
	port (
		clock : in std_logic;
		reset : in std_logic;

		in_i     : in signed(15 downto 0);
		in_q   	 : in signed(15 downto 0);
		in_valid : in std_logic; 

		wclock : out std_logic;
        wdata  : out std_logic_vector(31 downto 0);
        wreq   : out std_logic;
        wempty : in std_logic;
        wfull  : in std_logic;
        wused  : in std_logic_vector(11 downto 0)
	);
end entity;

architecture rtl of processing_bridge is
begin
	wdata <= std_logic_vector(in_i & in_q);
	wreq <= in_valid;
	wclock <= clock;
end architecture rtl;
