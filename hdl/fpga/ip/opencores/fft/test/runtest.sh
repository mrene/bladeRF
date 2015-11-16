#!/bin/bash

bladeRF-cli -l /home/mrene/bladerf/hdl/quartus/work/output_files/hosted_fft.rbf
make -f Makefile.test
./test fft
#bladeRF-cli -l ~/hostedx115-latest.rbf
bladeRF-cli -s rxtest.bladerf


