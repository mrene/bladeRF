-- Copyright (c) 2013 Nuand LLC
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

library work ;
    use work.cordic_p.all ;
    use work.nco_p.all ;

entity nco_tb is
end entity ; -- nco_tb

architecture arch of nco_tb is

    signal clock    :   std_logic := '1' ;
    signal reset    :   std_logic := '1' ;

    signal inputs   :   nco_input_t := ( dphase => (others =>'0'), valid => '0' );
    signal outputs  :   nco_output_t ;

    procedure nop( signal clock : in std_logic ; count : in natural ) is
    begin
        for i in 1 to count loop
            wait until rising_edge( clock ) ;
        end loop ;
    end procedure ;

begin

    clock <= not clock after 1 ns ;

    U_nco : entity work.nco
      port map (
        clock   => clock,
        reset   => reset,
        inputs  => inputs,
        outputs => outputs
      ) ;


    U_file_writer : entity work.data_writer
        generic map(
            FILENAME => "nco_output.dat",
            DATA_WIDTH => 32
        )
        port map(
            reset => reset,
            clock => clock,

            data       => std_logic_vector(outputs.re & outputs.im),
            data_valid => outputs.valid
        );


    tb : process
    begin
        reset <= '1' ;
        nop( clock, 10 ) ;

        reset <= '0' ;
        nop( clock, 10 ) ;

        inputs.dphase <= to_signed(256, inputs.dphase'length);
        inputs.valid <= '1' ;

        nop ( clock, 1000000 );

        report "-- End of Simulation --" severity failure ;
    end process ;

end architecture ; -- arch
