# Multiplexer

## Packet format
HDR Size = 2 bytes
[len 16 bits] [stream id - 8 bits] [flags - 8 bits] [payload]

Flags:
startofpacket (1 << 0)
endofpacket (1 << 1)

Input side:
Data gets assembled in a per-stream fifo, each of those can be in its own clock domain.
If the startofpacket or endofpacket flag is asserted, the current index is stored 

Output side:
Look for available data
Build + send header
Only transmit [maxlen] bytes - truncate the packet if a startofpacket/endofpacket index exists
If a such index exists, transmit a special 0 length packet with the flags set

## Configuration
Target: NIOS_PKT_8x8_TARGET_USR1
Base: MULTIPLEXER_CONTROLLER_0_BASE
Format: 8x8
Layout:
0: Enabled bitmask (bits 0 1 2 controlling their respective stream) - default enabled


# Analysis
## FFT
### Configuration
Target: NIOS_PKT_8x32_TARGET_USR1+3
Base: FFT_BASE
Format: 8x32
Layout:
0: Control Reg (Bit 0: enabled)
1: Counter MSB 
2: Counter LSB

# DDC Chain
## 1. Complex FIR Filter
### Configuration
Target: NIOS_PKT_8x32_TARGET_USR1
Base: RX_DDC_FILTER_BASE
Format: 8x32
Layout: 
0: Control Reg (Bit 0: enabled) - default disabled (passthrough)
1..50: Complex FIR Coefficient (16 bit signed + 16 bit signed)


## 2. Rotator
Uses a 12-bit cordic NCO to frequency-shift the input stream
### Configuration
Target: NIOS_PKT_8x32_TARGET_USR1+1
Base: RX_DDC_ROTATOR_BASE
Format: 8x32
Layout:
0:
Bit 31: Enabled (default false - passthrough)
Bits 0-15: Multiplying frequency is integer radians 

## 3. Decimator
Decimates by averagering [factor] samples 

### Configuration
Target: NIOS_PKT_8x32_TARGET_USR1+2
Base: RX_DDC_DECIMATOR_BASE
Format: 8x32
Layout:
0: Bit 31: Enabled (default false - passthrough)
0: Bits 0-15 Decimation factor (unsigned)


