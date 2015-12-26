# TCL File Generated by Component Editor 15.0
# Thu Dec 24 00:26:10 EST 2015
# DO NOT MODIFY


# 
# rotator "Complex Rotator" v1.0
#  2015.12.24.00:26:10
# 
# 

# 
# request TCL package from ACDS 15.0
# 
package require -exact qsys 15.0


# 
# module rotator
# 
set_module_property DESCRIPTION ""
set_module_property NAME rotator
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "Complex Rotator"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL rotator
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file rotator.vhd VHDL PATH ../../nuand/rotator/vhdl/rotator.vhd TOP_LEVEL_FILE
add_fileset_file cordic.vhd VHDL PATH ../../nuand/synthesis/cordic.vhd
add_fileset_file nco.vhd VHDL PATH ../../nuand/synthesis/nco.vhd

add_fileset SIM_VHDL SIM_VHDL "" ""
set_fileset_property SIM_VHDL TOP_LEVEL rotator
set_fileset_property SIM_VHDL ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VHDL ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file rotator_tb.vhd VHDL PATH ../../nuand/rotator/vhdl/tb/rotator_tb.vhd
add_fileset_file rotator.vhd VHDL PATH ../../nuand/rotator/vhdl/rotator.vhd
add_fileset_file cordic.vhd VHDL PATH ../../nuand/synthesis/cordic.vhd
add_fileset_file nco.vhd VHDL PATH ../../nuand/synthesis/nco.vhd


# 
# parameters
# 
add_parameter ADDR_WIDTH POSITIVE 8
set_parameter_property ADDR_WIDTH DEFAULT_VALUE 8
set_parameter_property ADDR_WIDTH DISPLAY_NAME ADDR_WIDTH
set_parameter_property ADDR_WIDTH TYPE POSITIVE
set_parameter_property ADDR_WIDTH UNITS None
set_parameter_property ADDR_WIDTH HDL_PARAMETER true
add_parameter DATA_WIDTH POSITIVE 32
set_parameter_property DATA_WIDTH DEFAULT_VALUE 32
set_parameter_property DATA_WIDTH DISPLAY_NAME DATA_WIDTH
set_parameter_property DATA_WIDTH TYPE POSITIVE
set_parameter_property DATA_WIDTH UNITS None
set_parameter_property DATA_WIDTH HDL_PARAMETER true
add_parameter DATA_SCALE POSITIVE 32
set_parameter_property DATA_SCALE DEFAULT_VALUE 32
set_parameter_property DATA_SCALE DISPLAY_NAME DATA_SCALE
set_parameter_property DATA_SCALE TYPE POSITIVE
set_parameter_property DATA_SCALE UNITS None
set_parameter_property DATA_SCALE HDL_PARAMETER true
add_parameter OUTPUT_SHIFT POSITIVE 12
set_parameter_property OUTPUT_SHIFT DEFAULT_VALUE 12
set_parameter_property OUTPUT_SHIFT DISPLAY_NAME OUTPUT_SHIFT
set_parameter_property OUTPUT_SHIFT TYPE POSITIVE
set_parameter_property OUTPUT_SHIFT UNITS None
set_parameter_property OUTPUT_SHIFT HDL_PARAMETER true


# 
# display items
# 


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point in
# 
add_interface in avalon_streaming end
set_interface_property in associatedClock clock
set_interface_property in associatedReset reset
set_interface_property in dataBitsPerSymbol 8
set_interface_property in errorDescriptor ""
set_interface_property in firstSymbolInHighOrderBits true
set_interface_property in maxChannel 0
set_interface_property in readyLatency 0
set_interface_property in ENABLED true
set_interface_property in EXPORT_OF ""
set_interface_property in PORT_NAME_MAP ""
set_interface_property in CMSIS_SVD_VARIABLES ""
set_interface_property in SVD_ADDRESS_GROUP ""

add_interface_port in asi_in_data data Input 32
add_interface_port in asi_in_valid valid Input 1
add_interface_port in asi_in_ready ready Output 1


# 
# connection point out
# 
add_interface out avalon_streaming start
set_interface_property out associatedClock clock
set_interface_property out associatedReset reset
set_interface_property out dataBitsPerSymbol 8
set_interface_property out errorDescriptor ""
set_interface_property out firstSymbolInHighOrderBits true
set_interface_property out maxChannel 0
set_interface_property out readyLatency 0
set_interface_property out ENABLED true
set_interface_property out EXPORT_OF ""
set_interface_property out PORT_NAME_MAP ""
set_interface_property out CMSIS_SVD_VARIABLES ""
set_interface_property out SVD_ADDRESS_GROUP ""

add_interface_port out aso_out_data data Output 32
add_interface_port out aso_out_valid valid Output 1


# 
# connection point config
# 
add_interface config avalon end
set_interface_property config addressUnits WORDS
set_interface_property config associatedClock clock
set_interface_property config associatedReset reset
set_interface_property config bitsPerSymbol 8
set_interface_property config burstOnBurstBoundariesOnly false
set_interface_property config burstcountUnits WORDS
set_interface_property config explicitAddressSpan 0
set_interface_property config holdTime 0
set_interface_property config linewrapBursts false
set_interface_property config maximumPendingReadTransactions 0
set_interface_property config maximumPendingWriteTransactions 0
set_interface_property config readLatency 0
set_interface_property config readWaitTime 1
set_interface_property config setupTime 0
set_interface_property config timingUnits Cycles
set_interface_property config writeWaitTime 0
set_interface_property config ENABLED true
set_interface_property config EXPORT_OF ""
set_interface_property config PORT_NAME_MAP ""
set_interface_property config CMSIS_SVD_VARIABLES ""
set_interface_property config SVD_ADDRESS_GROUP ""

add_interface_port config avs_config_address address Input addr_width
add_interface_port config avs_config_read read Input 1
add_interface_port config avs_config_readdata readdata Output data_width
add_interface_port config avs_config_write write Input 1
add_interface_port config avs_config_writedata writedata Input data_width
set_interface_assignment config embeddedsw.configuration.isFlash 0
set_interface_assignment config embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment config embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment config embeddedsw.configuration.isPrintableDevice 0


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clock clk Input 1

