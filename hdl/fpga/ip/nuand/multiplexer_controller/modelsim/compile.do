vlib nuand

vcom -work nuand -2008 ../../simulation/util.vhd
vcom -work nuand -2008 ../../synthesis/sampling_bridge.vhd
vcom -work nuand -2008 ../../../altera/multiplexer_fifo/multiplexer_fifo.vhd

vcom -work nuand -2008 ../../../opencores/fft/fft_len.vhd
vcom -work nuand -2008 ../../../opencores/fft/icpx_pkg.vhd
vcom -work nuand -2008 ../../../opencores/fft/fft_support.vhd
vcom -work nuand -2008 ../../../opencores/fft/dpram_rbw_inf.vhd
vcom -work nuand -2008 ../../../opencores/fft/icpxram_rbw.vhd
vcom -work nuand -2008 ../../../opencores/fft/butterfly_d3.vhd
vcom -work nuand -2008 ../../../opencores/fft/icpx_mul_d3.vhd
vcom -work nuand -2008 ../../../opencores/fft/dpram_inf.vhd
vcom -work nuand -2008 ../../../opencores/fft/fft_data_switch.vhd
vcom -work nuand -2008 ../../../opencores/fft/ram_fifo.vhd
vcom -work nuand -2008 ../../../opencores/fft/interleaver.vhd
vcom -work nuand -2008 ../../../opencores/fft/fft_engine.vhd

vcom -work nuand -2008 ../../fft/vhdl/fft.vhd

vcom -work nuand -2008 ../vhdl/multiplexer.vhd
vcom -work nuand -2008 ../vhdl/tb/multiplexer_tb.vhd

