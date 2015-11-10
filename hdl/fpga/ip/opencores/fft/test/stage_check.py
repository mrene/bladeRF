#!/usr/bin/env python

import argparse
import re
from pprint import pprint
import numpy
import sys

NUM_STAGES=10

def parse_modelsim_file(filename):
	"""
	Opens a modelsim transcript and load all values
	"""

	stages = [ ]


	for i in range(0,NUM_STAGES):
		stages += [ {
			"IN": [ [], [] ],
			"OUT": [ [], [] ]
		}]

	# Line format:
	# ** Note: STAGE8-OUT1 -2 -21
	#    Time: 100 us  Iteration: 0  Instance: /fft_engine_tb/fft_engine_1/g1(8)/i3/fft_switch_1
	expr = re.compile(r"STAGE(\d)-(IN|OUT)(\d) (-?\d+) (-?\d+)")
	time_expr = re.compile(r"Time: ((\d+) ((.?)s))")

	with open(filename, "r") as fp:
		found_note = False
		values = (0, 0)
		stage = 0
		direction = "IN"
		index = 0

		for line in fp:
			if not found_note:
				matches = expr.findall(line)
				if len(matches) > 0:
					m = matches[0]
					values = (int(m[3]), int(m[4]))
					stage = int(m[0])
					direction = m[1]
					index = int(m[2])
					found_note = True
			else:
				time_matches = time_expr.findall(line)
				stages[stage][direction][index] += [ ( values, time_matches[0][0] ) ]

				# print "Found:  Stage: %s Direction: %s Index: %s Time: %s -- %s" % (stage, direction, index, time_matches[0][0], values)

				found_note = False
	return stages


def parse_file(filename):
	"""
	Opens a report trace and load all values
	"""

	stages = [ ]

	for i in range(0,NUM_STAGES):
		stages += [ {
			"IN": [ [], [] ],
			"OUT": [ [], [] ]
		}]

	# Line format:
	# src/fft_data_switch.vhd:201:9:@1080ns:(report note): STAGE0-OUT0 3036 2675
	expr = re.compile(r"STAGE(\d)-(IN|OUT)(\d) (-?\d+) (-?\d+)")
	time_expr = re.compile(r"@(\d+[pnum]s)")

	with open(filename, "r") as fp:
		for line in fp:
			matches = expr.findall(line)
			time_matches = time_expr.findall(line)
			if len(matches) > 0:
				m = matches[0]
				values = (int(m[3]), int(m[4]))
				stage = int(m[0])
				direction = m[1]
				index = int(m[2])
				stages[stage][direction][index] += [ ( values, time_matches[0] ) ]

	return stages

def nzi(lst):
	"""
	Finds the first non-zero index of lst
	"""
	for index, val in enumerate(lst):
		if val[0][0] != 0 and val[0][1] != 0:
			return index

	return -1


def values(lst):
	return [i[0] for i in lst]

def format(i):
	return "{0:04X}".format(i & 0xFFFF)

def print_shorts(lst):
	print 'RE: ' + ' '.join([format(i[0][0]) for i in lst])
	print 'IM: ' + ' '.join([format(i[0][1]) for i in lst])


def main():
	parser = argparse.ArgumentParser(description='Compares FFT stages between reference and refactored implementation')
	parser.add_argument('--size', '-n', metavar='n', type=int, nargs=1, help='Number of samples to compare')
	parser.add_argument('--ref', metavar='r', type=str, nargs=1, help='Reference implementation')
	parser.add_argument('--target', metavar='t', type=str, nargs=1, help='Implementation under test')
	parser.add_argument('-k', metavar='k', dest='keep', type=bool, help='Keep going')
	args = parser.parse_args()	

	ref_data = parse_file(args.ref[0])
	target_data = parse_modelsim_file(args.target[0])
	n = args.size[0]

	for stage in range(0, NUM_STAGES):
		print "Verifying stage %d..." % stage
		for direction in [ 'IN', 'OUT' ]:
			for index in range(0,2):
				ref = ref_data[stage][direction][index]
				target = target_data[stage][direction][index]

				nzi_ref = nzi(ref)
				nzi_target = nzi(target)

				ref_slice = ref[nzi_ref:(nzi_ref + n)]
				target_slice = target[nzi_target:(nzi_target + n)]

				# pprint(ref[nzi_ref:(nzi_ref + n)])
				# pprint(target[nzi_target:(nzi_target + n)])

				if numpy.allclose(values(ref_slice), values(target_slice), atol=4):
					print "Stage %d %s%d PASS (%d samples)" % (stage, direction, index, len(target_slice))
				else:
					print "Stage %d %s%d FAIL (%d samples)" % (stage, direction, index, len(target_slice))

					# Find the index at which they differ
					for i, val in enumerate(ref_slice):
						if val[0] != target_slice[i][0]:
							start = max(min(0, i - 4), 0)
							end = start + 8
							print "Found discrepency at %s" % target_slice[i][1]
							print "Ref:"
							print_shorts(ref_slice[start:end])
							print "\nActual:"
							print_shorts(target_slice[start:end])
							if args.keep:
								break
							else:
								sys.exit()


if __name__ == "__main__":
	main();

