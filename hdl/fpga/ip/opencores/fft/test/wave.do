onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fft_engine_tb/Clk
add wave -noupdate -group Input -radix hexadecimal -childformat {{/fft_engine_tb/din.Re -radix hexadecimal -childformat {{/fft_engine_tb/din.Re(21) -radix hexadecimal} {/fft_engine_tb/din.Re(20) -radix hexadecimal} {/fft_engine_tb/din.Re(19) -radix hexadecimal} {/fft_engine_tb/din.Re(18) -radix hexadecimal} {/fft_engine_tb/din.Re(17) -radix hexadecimal} {/fft_engine_tb/din.Re(16) -radix hexadecimal} {/fft_engine_tb/din.Re(15) -radix hexadecimal} {/fft_engine_tb/din.Re(14) -radix hexadecimal} {/fft_engine_tb/din.Re(13) -radix hexadecimal} {/fft_engine_tb/din.Re(12) -radix hexadecimal} {/fft_engine_tb/din.Re(11) -radix hexadecimal} {/fft_engine_tb/din.Re(10) -radix hexadecimal} {/fft_engine_tb/din.Re(9) -radix hexadecimal} {/fft_engine_tb/din.Re(8) -radix hexadecimal} {/fft_engine_tb/din.Re(7) -radix hexadecimal} {/fft_engine_tb/din.Re(6) -radix hexadecimal} {/fft_engine_tb/din.Re(5) -radix hexadecimal} {/fft_engine_tb/din.Re(4) -radix hexadecimal} {/fft_engine_tb/din.Re(3) -radix hexadecimal} {/fft_engine_tb/din.Re(2) -radix hexadecimal} {/fft_engine_tb/din.Re(1) -radix hexadecimal} {/fft_engine_tb/din.Re(0) -radix hexadecimal}}} {/fft_engine_tb/din.Im -radix hexadecimal}} -expand -subitemconfig {/fft_engine_tb/din.Re {-height 17 -radix hexadecimal -childformat {{/fft_engine_tb/din.Re(21) -radix hexadecimal} {/fft_engine_tb/din.Re(20) -radix hexadecimal} {/fft_engine_tb/din.Re(19) -radix hexadecimal} {/fft_engine_tb/din.Re(18) -radix hexadecimal} {/fft_engine_tb/din.Re(17) -radix hexadecimal} {/fft_engine_tb/din.Re(16) -radix hexadecimal} {/fft_engine_tb/din.Re(15) -radix hexadecimal} {/fft_engine_tb/din.Re(14) -radix hexadecimal} {/fft_engine_tb/din.Re(13) -radix hexadecimal} {/fft_engine_tb/din.Re(12) -radix hexadecimal} {/fft_engine_tb/din.Re(11) -radix hexadecimal} {/fft_engine_tb/din.Re(10) -radix hexadecimal} {/fft_engine_tb/din.Re(9) -radix hexadecimal} {/fft_engine_tb/din.Re(8) -radix hexadecimal} {/fft_engine_tb/din.Re(7) -radix hexadecimal} {/fft_engine_tb/din.Re(6) -radix hexadecimal} {/fft_engine_tb/din.Re(5) -radix hexadecimal} {/fft_engine_tb/din.Re(4) -radix hexadecimal} {/fft_engine_tb/din.Re(3) -radix hexadecimal} {/fft_engine_tb/din.Re(2) -radix hexadecimal} {/fft_engine_tb/din.Re(1) -radix hexadecimal} {/fft_engine_tb/din.Re(0) -radix hexadecimal}}} /fft_engine_tb/din.Re(21) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(20) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(19) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(18) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(17) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(16) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(15) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(14) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(13) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(12) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(11) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(10) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(9) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(8) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(7) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(6) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(5) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(4) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(3) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(2) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(1) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Re(0) {-height 17 -radix hexadecimal} /fft_engine_tb/din.Im {-height 17 -radix hexadecimal}} /fft_engine_tb/din
add wave -noupdate -group Input -radix hexadecimal /fft_engine_tb/din_valid
add wave -noupdate -group Butterfly1 -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/butterfly_1/din0
add wave -noupdate -group Butterfly1 -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/butterfly_1/din1
add wave -noupdate -group Butterfly1 -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/butterfly_1/din_valid
add wave -noupdate -group Butterfly1 -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/butterfly_1/dout0
add wave -noupdate -group Butterfly1 -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/butterfly_1/dout1
add wave -noupdate -group Butterfly1 -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/butterfly_1/tf
add wave -noupdate -group {FFT Switch 1} -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/i3/fft_switch_1/in0
add wave -noupdate -group {FFT Switch 1} -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/i3/fft_switch_1/in1
add wave -noupdate -group {FFT Switch 1} -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/i3/fft_switch_1/in_valid
add wave -noupdate -group {FFT Switch 1} -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/i3/fft_switch_1/out0
add wave -noupdate -group {FFT Switch 1} -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/i3/fft_switch_1/out1
add wave -noupdate -group {FFT Switch 1} -radix hexadecimal /fft_engine_tb/fft_engine_1/g1(0)/i3/fft_switch_1/valid
add wave -noupdate -expand -group Reorderer -childformat {{/fft_engine_tb/fft_engine_1/reorderer/out_data_a.Re -radix decimal} {/fft_engine_tb/fft_engine_1/reorderer/out_data_a.Im -radix decimal}} -expand -subitemconfig {/fft_engine_tb/fft_engine_1/reorderer/out_data_a.Re {-radix decimal} /fft_engine_tb/fft_engine_1/reorderer/out_data_a.Im {-radix decimal}} /fft_engine_tb/fft_engine_1/reorderer/out_data_a
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/out_valid
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/debug_head
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/debug_tail
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/debug_tail_delayed
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/debug_tail_delayed2
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/debug_tail_index
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/debug_tail_index_delayed
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/internal_new
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/internal_new_delayed
add wave -noupdate -expand -group Reorderer /fft_engine_tb/fft_engine_1/reorderer/out_sob
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {85327648 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 441
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {299956861 ps} {300002271 ps}
