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

  signal dptr                 : integer range 0 to 15;
  signal din, sout_a, sout_b  : icpx_number;
  signal saddr, saddr_rev     : unsigned(LOG2_FFT_LEN-2 downto 0);
  signal end_of_data, end_sim : boolean := false;
  signal valid, sout_new      : std_logic := '0';

  component fft_engine is
    generic (
      LOG2_FFT_LEN : integer);
    port (
      rst_n     : in  std_logic;
      clk       : in  std_logic;
      din       : in  icpx_number;
      valid     : out std_logic;
      --saddr     : out unsigned(LOG2_FFT_LEN-2 downto 0);
      --saddr_rev : out unsigned(LOG2_FFT_LEN-2 downto 0);
      sout_a     : out icpx_number;
      sout_b     : out icpx_number;
      sout_new : out std_logic
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
      sout_a      => sout_a,
      sout_b      => sout_b,
      sout_new  => sout_new,
      valid     => valid
  );
  -- clock generation

  Clk <= not Clk after 10 ns when end_sim = false else '0';

  -- waveform generation
  WaveGen_Proc : process
    file data_in         : text open read_mode is "data_in.txt";
    variable input_line  : line;
    file data_out        : text open write_mode is "data_out.txt";
    variable output_line : line;
    variable tre, tim    : real;
    constant sep         : string := " ";
    variable vout        : T_OUT_DATA;
  begin
    -- insert signal assignments here
    wait until Clk = '1';
    wait for 15 ns;
    wait until clk = '0';
    wait until clk = '1';
    rst_n <= '1';
    dptr  <= 0;
        
    write(output_line, string'("VHDL GENERATED"));
    writeline(data_out, output_line);

    l1 : while not end_sim loop
      if not endfile(data_in) then
        readline(data_in, input_line);
        read(input_line, tre);
        read(input_line, tim);
      else
        end_of_data <= true;
      end if;
      din <= cplx2icpx(complex'(tre, tim));
      if dptr < 15 then
        dptr <= dptr + 1;
      else
        dptr <= 0;
      end if;

      if (sout_new = '1') then
        write(output_line, string'("FFT RESULT BEGIN"));
        writeline(data_out, output_line);
      end if;

      if (valid = '1') then
        write(output_line, integer'image(to_integer(sout_a.re)));
        write(output_line, sep);
        write(output_line, integer'image(to_integer(sout_a.im)));
        writeline(data_out, output_line);

        write(output_line, integer'image(to_integer(sout_b.re)));
        write(output_line, sep);
        write(output_line, integer'image(to_integer(sout_b.im)));
        writeline(data_out, output_line);
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


