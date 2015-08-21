-------------------------------------------------------------------------------
-- Title      : Testbench for design "fft_top"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : fft_top_tb.vhd
-- Author     : Wojciech Zabolotny
-- Company    : 
-- License    : BSD
-- Created    : 2014-01-21
-- Last update: 2015-03-24
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-01-21  1.0      wzab    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.math_complex.all;
library std;
use std.textio.all;
library work;
use work.fft_len.all;
use work.icpx.all;
use work.fft_support_pkg.all;

-------------------------------------------------------------------------------

entity fft_engine_tb is

end fft_engine_tb;

-------------------------------------------------------------------------------

architecture beh1 of fft_engine_tb is

  type T_OUT_DATA is array (0 to FFT_LEN-1) of icpx_number;

  signal din, sout_a, sout_b  : icpx_number;
  signal saddr, saddr_rev     : unsigned(LOG2_FFT_LEN-2 downto 0);
  signal end_of_data, end_sim : boolean := false;
  signal valid, out_sob, din_valid : std_logic := '0';

  component fft_engine is
    generic (
      LOG2_FFT_LEN : integer);
    port (
      rst_n     : in  std_logic;
      clk       : in  std_logic;
      din       : in  icpx_number;
      valid     : out std_logic;
      din_valid : in std_logic;
      --saddr     : out unsigned(LOG2_FFT_LEN-2 downto 0);
      --saddr_rev : out unsigned(LOG2_FFT_LEN-2 downto 0);
      sout_a     : out icpx_number;
      sout_b     : out icpx_number;
      out_sob : out std_logic
      );
  end component fft_engine;

  -- component ports
  signal rst_n : std_logic := '0';

  -- clock
  signal Clk : std_logic := '1';

  signal count : integer := 0;

begin  -- beh1

  process (clk, rst_n) is
  begin
    if rst_n = '0' then
      count <= 0;
    elsif rising_edge(clk) then
      count <= count + 1;
    end if;
  end process;


  -- component instantiation
  fft_engine_1 : entity work.fft_engine
    generic map (
      LOG2_FFT_LEN => LOG2_FFT_LEN)
    port map (
      rst_n     => rst_n,
      clk       => clk,
      din       => din,
      din_valid => din_valid,
      sout_a      => sout_a,
      sout_b      => sout_b,
      out_sob  => out_sob,
      valid     => valid
  );
  -- clock generation

  Clk <= not Clk after 10 ns when end_sim = false else '0';

  -- waveform generation
  WaveGen_Proc : process
    type bin_t is file of character ;
    file data_in         : bin_t;
    variable input_line  : line;
    file data_out        : text open write_mode is "data_out.txt";
    variable output_line : line;
    variable tre, tim    : real;
    constant sep         : string := " ";
    variable vout        : T_OUT_DATA;
    variable interval : boolean := false;
    variable c : character;
    variable tmp : integer;
    variable data : std_logic_vector(31 downto 0);
    variable fs : file_open_status ;
  begin
    -- insert signal assignments here
    wait until Clk = '1';
    wait for 15 ns;
    wait until clk = '0';
    wait until clk = '1';
    rst_n <= '1';

    --for i in 0 to 300 loop
    --wait until clk = '0';
    --  wait until clk = '1';
    --  wait until clk = '0';

    --  din_valid <= '0';
    --  din <= icpx_zero;
    --end loop;
        
    write(output_line, string'("VHDL GENERATED"));
    writeline(data_out, output_line);

    --character open read_mode is "data_in.txt";
    file_open(fs, data_in, "data_in.bin", READ_MODE);
    if( fs /= OPEN_OK ) then
        report "File open issues" severity failure ;
     end if ;

    l1 : while not end_sim loop
      if not endfile(data_in) then
        if interval = true then
          din_valid <= '0';
          din <= icpx_zero;
          interval := false;
        else
          interval := true;
          --readline(data_in, input_line);
          read(data_in, c);
          tmp := integer(natural(character'pos(c)));
          data(23 downto 16) := std_logic_vector(to_unsigned(tmp,8));
          read(data_in, c);
          tmp := integer(natural(character'pos(c)));
          data(31 downto 24) := std_logic_vector(to_unsigned(tmp,8));
          
          read(data_in, c);
          tmp := integer(natural(character'pos(c)));
          data(7 downto 0) := std_logic_vector(to_unsigned(tmp,8));
          read(data_in, c);
          tmp := integer(natural(character'pos(c)));
          data(15 downto 8) := std_logic_vector(to_unsigned(tmp,8));


          din_valid <= '1';
          --din <= cplx2icpx(complex'(tre, tim));
          din <= stlv2icpx(data);
        end if;
      else
        din_valid <= '0';
        end_of_data <= true;
      end if;


      if (out_sob = '1') then
        write(output_line, string'("FFT RESULT BEGIN"));
        writeline(data_out, output_line);
      end if;

      if (valid = '1') then
        write(output_line, integer'image(to_integer(sout_a.re)));
        write(output_line, sep);
        write(output_line, integer'image(to_integer(sout_a.im)));
        writeline(data_out, output_line);

        --write(output_line, integer'image(to_integer(sout_b.re)));
        --write(output_line, sep);
        --write(output_line, integer'image(to_integer(sout_b.im)));
        --writeline(data_out, output_line);
      end if;

      -- If the full set of data is calculated, write the output buffer
      --if count mod FFT_LEN-1 = 0 then
      --  write(output_line, string'("FFT RESULT BEGIN"));
      --  writeline(data_out, output_line);
      --  for i in 0 to FFT_LEN-1 loop
      --    write(output_line, integer'image(to_integer(vout(i).re)));
      --    write(output_line, sep);
      --    write(output_line, integer'image(to_integer(vout(i).im)));
      --    writeline(data_out, output_line);
      --  end loop;  -- i
      --  write(output_line, string'("FFT RESULT END"));
      --  writeline(data_out, output_line);
      --  exit l1 when end_of_data;
      --end if;

      wait until clk = '0';
      wait until clk = '1';
    end loop l1;
    end_sim <= true;
    
  end process WaveGen_Proc;

  

end beh1;


