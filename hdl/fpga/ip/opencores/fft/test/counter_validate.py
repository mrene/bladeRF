#!/usr/bin/env python

import itertools
from scipy import signal
from scipy.fftpack import fft 
import numpy
import struct
from pprint import pprint

## Data sources

def counter():
	"""
	The 12-bit counter starts at 256 for the I sample, and increases by 1 until it reaches 2047,
	at which it overflows back to -2047. Q is always set to -I.
	"""
	i = 256
	while True:
		yield complex(i, -i)

		if i < 2047:
			i = i + 1
		else:
			i = -2047

def binaryfile(filename):
	"""
	Reads an interleaved raw I/Q file (16 bits/sample)
	"""
	with open(filename, "rb") as f:
		while True:
			data = f.read(2)
			if not data:
				break

			i = struct.unpack('>h', data)[0]

			data = f.read(2)
			if not data:
				break

			q = struct.unpack('>h', data)[0]

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
		fmt_data = [fmt_str.format(int(i.real) & 0x3fffff, int(i.imag) & 0x3fffff) for i in data]
	elif fmt == 'int':
		fmt_str = "{0} {1}";
		fmt_data = [fmt_str.format(int(i.real), int(i.imag)) for i in data]
	elif fmt == 'float':
		fmt_str = "{0} {1}";
		fmt_data = [fmt_str.format(i.real, i.imag) for i in data]

	print "Re\tIm\n" + "\n".join(fmt_data)


def main():
	log2fftlen = 10
	fftlen = 2 ** log2fftlen
	icpx_width = 16 # Bits per sample
	scale = 2 ** (icpx_width-2)

	# Initialize the 12-bit counter (same as signal_generator.vhd)
	#src = counter()
	#src = binaryfile('./data_in.bin')
	src = textfile('./data_in.txt', parse=floatparse)

	# Take the first fftlen samples
	samples = list(itertools.islice(src, 0, fftlen))

	# Scale samples to fixed point value
	samples = [x * scale for x in samples]

	#print_samples(samples,fmt='int')

	# Scaling to match the division by 2 in each butterfly operation
	samples = [x / float(fftlen) for x in samples]
	
	#print_samples(samples,fmt='hex')

	print "############################################"

	# Get our window function
	win = signal.hann(fftlen)

	# Apply the window function to our signal
	data = numpy.multiply(samples, win)

	# Perform the fft
	bins = fft(data)

	# Rounding
	bins = [complex(round(x.real), round(x.imag)) for x in bins]

	print_samples(bins,fmt='hex')

if __name__ == "__main__":
	main();

