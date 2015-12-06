---
--- Qsys component exposing FFT interface to NIOS system
---

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;
    use work.fft_len.all;
    use work.icpx.all;
    use work.fft_support_pkg.all;
entity fft is
    generic (
        -- Config register settings
        ADDR_WIDTH : positive := 8;
        DATA_WIDTH : positive := 32
    );
    port (
        clock : in std_logic;
        reset : in std_logic;

        -- Avalon-ST Sink (Input)
        asi_in_data  : in std_logic_vector(31 downto 0);
        asi_in_valid : in std_logic;

        -- Avalon-ST Source (Output)
        aso_out_data          : out std_logic_vector(31 downto 0);
        aso_out_valid         : out std_logic; 
        aso_out_startofpacket : out std_logic;
        aso_out_endofpacket   : out std_logic;


        -- Avalon-MM Slave
        avs_config_address       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        avs_config_read          : in  std_logic;
        avs_config_readdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        avs_config_write         : in  std_logic;
        avs_config_writedata     : in  std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;


architecture rtl of fft is
    signal in_i : signed(15 downto 0);
    signal in_q : signed(15 downto 0);

    signal sample_din : icpx_number;
    signal sample_fft : icpx_number;

    signal out_i : signed(15 downto 0);
    signal out_q : signed(15 downto 0);

    -- Memory-mapped area
    -- Address 0x0
    signal ctrl_reg : std_logic_vector(31 downto 0) := (others => '0');
    -- Address 0x1 and 0x2
    -- Coundown setting
    -- Specifies how many samples the component should wait before taking an FFT
    -- If 0, the component runs continuously and deliveres a complete N-point FFT every N/2 points,
    signal ctrl_countdown_setting : unsigned(63 downto 0) := to_unsigned(0, 64);
    -- End memory-mapped area

    signal fft_enable : std_logic; -- control(0)
    signal fft_reset  : std_logic;
    -- Internal state
    type fft_state_t is (ST_COUNTDOWN, ST_CAPTURING, ST_RESET);
    
    signal state         : fft_state_t;
    signal countdown     : unsigned(63 downto 0);
    signal startofpacket : std_logic;
    signal endofpacket   : std_logic;
    signal valid         : std_logic;
begin
    fft_enable <= ctrl_reg(0);

    counter : process(clock,reset)
    begin
        if reset = '1' then
            countdown <= to_unsigned(0, countdown'length);
            fft_reset <= '1';
            state <= ST_RESET;
        elsif rising_edge(clock) then
            case state is
                when ST_COUNTDOWN =>
                    if countdown = to_unsigned(0, countdown'length) then
                        fft_reset <= '0';
                        state <= ST_CAPTURING;
                    else 
                        countdown <= countdown - 1;
                    end if;

                when ST_CAPTURING =>
                    -- Always stay in ST_CAPTURING if the countdown
                    -- setting is set to 0
                    if ctrl_countdown_setting /= 0 and endofpacket = '1' then
                        fft_reset <= '1';
                        state <= ST_RESET;
                    end if;

                when ST_RESET =>
                    if ctrl_countdown_setting = 0 then
                        fft_reset <= '0';
                        state <= ST_CAPTURING;
                    else
                        countdown <= ctrl_countdown_setting;
                        state <= ST_COUNTDOWN;
                    end if;
            end case;
        end if;
    end process;
    
    mm_read : process(clock)
    begin
        if rising_edge(clock) then
            if avs_config_read = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 => avs_config_readdata <= ctrl_reg;
                    when 1 => avs_config_readdata <= std_logic_vector(ctrl_countdown_setting(63 downto 32));
                    when 2 => avs_config_readdata <= std_logic_vector(ctrl_countdown_setting(31 downto 0));
                    when others => avs_config_readdata <= x"ffffffff";
                end case;
            end if;
        end if;
    end process;

    mm_write : process(clock)
    begin
        if rising_edge(clock) then
            if avs_config_write = '1' then
                case to_integer(unsigned(avs_config_address)) is
                    when 0 => ctrl_reg <= avs_config_writedata;
                    when 1 => ctrl_countdown_setting(63 downto 32) <= unsigned(avs_config_writedata);
                    when 2 => ctrl_countdown_setting(31 downto 0)  <= unsigned(avs_config_writedata);
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Map FFT Input
    in_i <= signed(asi_in_data(31 downto 16));
    in_q <= signed(asi_in_data(15 downto 0));

    sample_din.Re <= shift_left(resize(in_i, ICPX_WIDTH), 14) when asi_in_valid = '1' else (others => '0');
    sample_din.Im <= shift_left(resize(in_q, ICPX_WIDTH), 14) when asi_in_valid = '1' else (others => '0');

    U_rx_fft : entity work.fft_engine
    generic map (
        LOG2_FFT_LEN => 14)
    port map (
        rst_n     => not (reset or fft_reset),
        clk       => clock,
        din       => sample_din,
        din_valid => asi_in_valid,

        sout      => sample_fft,
        out_sob   => startofpacket,
        out_eob   => endofpacket,
        valid     => valid
    );


    -- FIXME - Hand-adjusted window
    out_i <= sample_fft.Re(17 downto 2);
    out_q <= sample_fft.Im(17 downto 2);

    aso_out_data <= std_logic_vector(out_i & out_q);
    aso_out_startofpacket <= startofpacket;
    aso_out_endofpacket <= endofpacket;
    aso_out_valid <= valid when state = ST_CAPTURING else '0';
end rtl;
