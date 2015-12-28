
import itertools
from scipy import signal
from scipy.fftpack import fft 
import numpy
import struct
from pprint import pprint

## Data sources

def counter(start=256):
	"""
	The 12-bit counter starts at 256 for the I sample, and increases by 1 until it reaches 2047,
	at which it overflows back to -2047. Q is always set to -I.
	"""
	i = start
	while True:
		yield complex(i, -i)

		if i < 2047:
			i = i + 1
		else:
			i = -2047

def binaryfile(filename, samplesize=32):
	"""
	Reads an interleaved raw I/Q file (32 bits/sample)
	"""
	if samplesize == 32:
		fmt = 'i'
	elif samplesize == 16:
		fmt = 'h'
	else:
		raise Exception("No such format for" + samplesize)
	with open(filename, "rb") as f:
		while True:
			data = f.read(samplesize/8)
			if not data:
				break

			# print 'fmt' + fmt
			i = struct.unpack('<' + fmt, data)[0]

			data = f.read(samplesize/8)
			if not data:
				break

			q = struct.unpack('<' + fmt, data)[0]

			yield complex(i,q)


## Text file
def floatparse(line):
	return complex(*[float(i) for i in line.split(' ')])

def intparse(line):
	return complex(*[int(i) for i in line.split(' ')])

def hexparse(line):
	return complex(*[struct.unpack('>h', i.decode('hex')) for i in line.split(' ')])


def textfile(filename, parse=floatparse):
	"""
	Reads one line per sample
	Parses samples using the parse argument
	"""
	with open(filename, "r") as fp:
		for line in fp:
			sample = parse(line)
			if sample is not None:
				yield sample

## Utility 

def print_samples(data,fmt='hex'):
	fmt_str = ""

	if fmt == 'hex': 
		fmt_str = "{0:04x} {1:04x}";
		fmt_data = [fmt_str.format(int(i.real) & 0xFFFF, int(i.imag) & 0xFFFF) for i in data]
	elif fmt == 'int':
		fmt_str = "{0} {1}";
		fmt_data = [fmt_str.format(int(i.real), int(i.imag)) for i in data]
	elif fmt == 'float':
		fmt_str = "{0} {1}";
		fmt_data = [fmt_str.format(i.real, i.imag) for i in data]

	print "Re\tIm\n" + "\n".join(fmt_data)

def packetReader(filename):
	with open(filename, "r") as fp:
		while True:
			# Read header
			data = fp.read(4)
			if not data:
				break
			header = struct.unpack('<i', data)[0]

			# Swap the two shorts to copy with bladerf-cli behaviour
			header = (header & 0xFFFF) << 16 | (header >> 16)

			# First 16 bits are the data length
			packet_len = (header >> 16) & 0xFFFF
			packet_len = packet_len+4

			stream_id = (header >> 8) & 0xFF

			sanity = header & 0xFF

			if sanity != 0xFF:
				raise "Sanity check failed"

			#print "Reading %d bytes\n" % packet_len
			# fp.read(4) # Discard 4 erroneous bytes
			data = fp.read(packet_len)

			yield {
				"packet_len": packet_len,
				"stream_id": stream_id,
				"data": data
			}

def packetfile(filename, stream_id):
	stream = packetReader(filename)
	for packet in stream:
		if packet["stream_id"] == stream_id:
			for j in range(0, len(packet['data']), 4):
				i = struct.unpack('<h', packet['data'][j:j+2])[0]
				q = struct.unpack('<h', packet['data'][j+2:j+4])[0]
				yield complex(i,q)

def plot_fft(data, samp_rate, center = 0):
    fftdata = np.fft.fft(data)
    freq = np.fft.fftfreq(len(data), 1./samp_rate)
    freq = np.add(freq, center)
    mag = [10 * np.log10(np.abs(x)) for x in fftdata]
    plt.figure(figsize=(13, 5))
    plt.ticklabel_format(useOffset=False,style='plain')
    plt.plot(freq, mag)
