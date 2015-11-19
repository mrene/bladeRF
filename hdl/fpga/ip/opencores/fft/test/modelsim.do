vlib nuand

vcom -work nuand -2008 ../../../nuand/simulation/util.vhd
vcom -work nuand -2008 ../../../nuand/simulation/fx3_model.vhd
vcom -work nuand -2008 ../../../nuand/simulation/lms6002d_model.vhd

vcom -work nuand -2008 ../../../nuand/synthesis/fifo_reader.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/fifo_writer.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/synchronizer.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/reset_synchronizer.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/signal_generator.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/tan_table.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/iq_correction.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/lms6002d/vhdl/lms6002d.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/tan_table.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/iq_correction.vhd
vcom -work nuand -2008 ../../../nuand/synthesis/handshake.vhd

vcom -work nuand -2008 ../../../altera/pll/pll.vhd
vcom -work nuand -2008 ../../../altera/fx3_pll/fx3_pll.vhd
vcom -work nuand -2008 ../../../altera/rx_fifo/rx_fifo.vhd
vcom -work nuand -2008 ../../../altera/tx_fifo/tx_fifo.vhd
vcom -work nuand -2008 ../../../altera/tx_meta_fifo/tx_meta_fifo.vhd
vcom -work nuand -2008 ../../../altera/rx_meta_fifo/rx_meta_fifo.vhd
vcom -work nuand -2008 ../../../altera/nios_system/simulation/nios_system.vhd

vcom -work nuand -2008 ../../../../platforms/bladerf/vhdl/fx3_gpif.vhd

vcom -work nuand -2008 ../../../../platforms/bladerf/vhdl/bladerf.vhd


vcom -work nuand -2008 ../../../../platforms/bladerf/vhdl/tb/bladerf_tb.vhd


vcom -check_synthesis -work nuand -2008 ../fft_len.vhd
vcom -check_synthesis -work nuand -2008 ../icpx_pkg.vhd
vcom -check_synthesis -work nuand -2008 ../fft_support.vhd
vcom -check_synthesis -work nuand -2008 ../dpram_rbw_inf.vhd
vcom -check_synthesis -work nuand -2008 ../icpxram_rbw.vhd
vcom -check_synthesis -work nuand -2008 ../butterfly_d3.vhd
vcom -check_synthesis -work nuand -2008 ../icpx_mul_d3.vhd
vcom -check_synthesis -work nuand -2008 ../dpram_inf.vhd
vcom -check_synthesis -work nuand -2008 ../fft_data_switch.vhd
vcom -check_synthesis -work nuand -2008 ../ram_fifo.vhd
vcom -check_synthesis -work nuand -2008 ../interleaver.vhd
vcom -check_synthesis -work nuand -2008 ../fft_engine.vhd
vcom -check_synthesis -work nuand -2008 ../fft_engine_tb.vhd

vsim -t 1ps nuand.fft_engine_tb

