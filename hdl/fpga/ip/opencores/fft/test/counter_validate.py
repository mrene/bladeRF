#!/usr/bin/env python
from util import *
import itertools
from scipy import signal
from scipy.fftpack import fft 
import numpy
import struct
from pprint import pprint

def main():
	log2fftlen = 10
	fftlen = 2 ** log2fftlen
	icpx_width = 16 # Bits per sample
	scale = 2 ** (icpx_width-2)
	round_mask = 2 ** 22 - 1

	# Initialize the 12-bit counter (same as signal_generator.vhd)
	#src = counter()
	#src = binaryfile('./data_in.bin')
	samples = textfile('./data_in.txt', parse=floatparse)

	# Scale samples to fixed point value
	samples = (x * scale for x in samples)

	#print_samples(samples,fmt='int')	

	# Scaling to match the division by 2 in each butterfly operation
	#samples = [x / float(fftlen) for x in samples]

	# Write to file
	#with open("./data_in.bin", "w") as fp:
	#	for x in samples:
	#		fp.write(struct.pack("<h", round(x.real)))
	#		fp.write(struct.pack("<h", round(x.imag)))

	# sys.exit()
	#return

	# Get our window function
	win = signal.hann(fftlen)

	# Take the first fftlen samples
	fftinput = list(itertools.islice(samples, 0, fftlen))
	while True:
		#print_samples(samples,fmt='hex')

		# data = [x / float(fftlen) for x in fftinput]
		data = fftinput

		# Apply the window function to our signal
		data = numpy.multiply(data, win)

		# Perform the fft
		bins = fft(data)

		# Rounding
		bins = [complex(round(x.real), round(x.imag)) for x in bins]

		# print "FFT RESULTS BEGIN"
		print_samples(bins,fmt='int')

		fftinput = fftinput[fftlen/2:] + list(itertools.islice(samples, 0, fftlen/2))

if __name__ == "__main__":
	main();

