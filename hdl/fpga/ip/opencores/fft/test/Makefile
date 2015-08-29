VHDLS = \
 ../fft_len.vhd \
 ../icpx_pkg.vhd \
 ../fft_support.vhd \
 ../dpram_rbw_inf.vhd \
 ../icpxram_rbw.vhd \
 ../butterfly_d3.vhd \
 ../icpx_mul_d3.vhd \
 ../dpram_inf.vhd \
 ../fft_data_switch.vhd \
 ../ram_fifo.vhd \
 ../fft_engine.vhd \
 ../fft_engine_tb.vhd


VHDLS2 = \
 ../fft_len.vhd \
 ../icpx_pkg.vhd \
 ../fft_support.vhd \
 ../dpram_rbw_inf.vhd \
 ../icpxram_rbw.vhd \
 ../butterfly_d3.vhd \
 ../icpx_mul_d3.vhd \
 ../dpram_inf.vhd \
 ../fft_data_switch.vhd \
 ../ram_fifo.vhd \
 ../ram_tb.vhd

#STD=standard
STD=synopsys
VSTD=93c
ENTITY=fft_engine_tb
ENTITY2=ram_tb
#RUN_OPTIONS= --stop-time=1000ns --wave=${ENTITY}.ghw 
RUN_OPTIONS=  --wave=${ENTITY}.ghw --stop-time=100000ns
RUN_OPTIONS2=  --wave=${ENTITY2}.ghw --stop-time=2000ns
#--trace-signals --trace-processes
#RUN_OPTIONS= 
#--trace-processes
all: ${ENTITY}.ghw
reader:   ${ENTITY} ${ENTITY}.ghw
	gtkwave ${ENTITY}.ghw ${ENTITY}.sav
${ENTITY}: ${VHDLS}
#	vhdlp -work fmf fmf/*.vhd
	ghdl -a -g --mb-comments --workdir=comp --std=${VSTD} --ieee=${STD} ${VHDLS} 
	ghdl -e -g --mb-comments --workdir=comp --std=${VSTD} -fexplicit --ieee=${STD} ${ENTITY}

${ENTITY}.ghw: ${ENTITY}
#	./${ENTITY} --wave=${ENTITY}.ghw  ${RUN_OPTIONS} --stop-time=50000ns 2>&1 > res.txt
	./${ENTITY} ${RUN_OPTIONS} 

#--------
reader2: ${ENTITY2} ${ENTITY2}.ghw
	gtkwave ${ENTITY2.ghw} ${ENTITY2}.sav

${ENTITY2}: ${VHDLS2}
	ghdl -a -g --mb-comments --workdir=comp --std=${VSTD} --ieee=${STD} ${VHDLS2}
	ghdl -e -g --mb-comments --workdir=comp --std=${VSTD} -fexplicit --ieee=${STD} ${ENTITY2}	

${ENTITY2}.ghw: ${ENTITY2}
	./${ENTITY2} ${RUN_OPTIONS2}

#> res.txt  2>&1 
clean:
	rm -f comp/* *.o *.vcd *.ghw events* ${ENTITY} ${ENTITY2}
	
