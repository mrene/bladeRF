# TCL File Generated by Component Editor 15.0
# Sun Jan 03 15:55:51 EST 2016
# DO NOT MODIFY


# 
# multiplexer_controller "Multiplexer Controller" v1.0
#  2016.01.03.15:55:51
# 
# 

# 
# request TCL package from ACDS 15.0
# 
package require -exact qsys 15.0


# 
# module multiplexer_controller
# 
set_module_property DESCRIPTION ""
set_module_property NAME multiplexer_controller
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "Multiplexer Controller"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL multiplexer_controller
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file multiplexer_controller.vhd VHDL PATH ../../nuand/multiplexer_controller/vhdl/multiplexer_controller.vhd TOP_LEVEL_FILE
add_fileset_file multiplexer.vhd VHDL PATH ../../nuand/synthesis/multiplexer.vhd
add_fileset_file multiplexer_fifo.vhd VHDL PATH ../multiplexer_fifo/multiplexer_fifo.vhd

add_fileset SIM_VHDL SIM_VHDL "" ""
set_fileset_property SIM_VHDL TOP_LEVEL multiplexer_controller
set_fileset_property SIM_VHDL ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VHDL ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file multiplexer_controller_tb.vhd VHDL PATH ../../nuand/multiplexer_controller/vhdl/tb/multiplexer_controller_tb.vhd
add_fileset_file multiplexer_controller.vhd VHDL PATH ../../nuand/multiplexer_controller/vhdl/multiplexer_controller.vhd
add_fileset_file multiplexer.vhd VHDL PATH ../../nuand/synthesis/multiplexer.vhd
add_fileset_file multiplexer_fifo.vhd VHDL PATH ../multiplexer_fifo/multiplexer_fifo.vhd


# 
# parameters
# 
add_parameter ADDR_WIDTH POSITIVE 8
set_parameter_property ADDR_WIDTH DEFAULT_VALUE 8
set_parameter_property ADDR_WIDTH DISPLAY_NAME ADDR_WIDTH
set_parameter_property ADDR_WIDTH TYPE POSITIVE
set_parameter_property ADDR_WIDTH UNITS None
set_parameter_property ADDR_WIDTH ALLOWED_RANGES 1:2147483647
set_parameter_property ADDR_WIDTH HDL_PARAMETER true
add_parameter DATA_WIDTH POSITIVE 8
set_parameter_property DATA_WIDTH DEFAULT_VALUE 8
set_parameter_property DATA_WIDTH DISPLAY_NAME DATA_WIDTH
set_parameter_property DATA_WIDTH TYPE POSITIVE
set_parameter_property DATA_WIDTH UNITS None
set_parameter_property DATA_WIDTH ALLOWED_RANGES 1:2147483647
set_parameter_property DATA_WIDTH HDL_PARAMETER true


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
# connection point in0
# 
add_interface in0 avalon_streaming end
set_interface_property in0 associatedClock clock
set_interface_property in0 associatedReset reset
set_interface_property in0 dataBitsPerSymbol 8
set_interface_property in0 errorDescriptor ""
set_interface_property in0 firstSymbolInHighOrderBits true
set_interface_property in0 maxChannel 0
set_interface_property in0 readyLatency 0
set_interface_property in0 ENABLED true
set_interface_property in0 EXPORT_OF ""
set_interface_property in0 PORT_NAME_MAP ""
set_interface_property in0 CMSIS_SVD_VARIABLES ""
set_interface_property in0 SVD_ADDRESS_GROUP ""

add_interface_port in0 asi_in0_data data Input 32
add_interface_port in0 asi_in0_valid valid Input 1


# 
# connection point in1
# 
add_interface in1 avalon_streaming end
set_interface_property in1 associatedClock clock
set_interface_property in1 associatedReset reset
set_interface_property in1 dataBitsPerSymbol 8
set_interface_property in1 errorDescriptor ""
set_interface_property in1 firstSymbolInHighOrderBits true
set_interface_property in1 maxChannel 0
set_interface_property in1 readyLatency 0
set_interface_property in1 ENABLED true
set_interface_property in1 EXPORT_OF ""
set_interface_property in1 PORT_NAME_MAP ""
set_interface_property in1 CMSIS_SVD_VARIABLES ""
set_interface_property in1 SVD_ADDRESS_GROUP ""

add_interface_port in1 asi_in1_data data Input 32
add_interface_port in1 asi_in1_valid valid Input 1
add_interface_port in1 asi_in1_startofpacket startofpacket Input 1
add_interface_port in1 asi_in1_endofpacket endofpacket Input 1


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
add_interface_port out aso_out_ready ready Input 1


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
# connection point in2
# 
add_interface in2 avalon_streaming end
set_interface_property in2 associatedClock clock
set_interface_property in2 associatedReset reset
set_interface_property in2 dataBitsPerSymbol 8
set_interface_property in2 errorDescriptor ""
set_interface_property in2 firstSymbolInHighOrderBits true
set_interface_property in2 maxChannel 0
set_interface_property in2 readyLatency 0
set_interface_property in2 ENABLED true
set_interface_property in2 EXPORT_OF ""
set_interface_property in2 PORT_NAME_MAP ""
set_interface_property in2 CMSIS_SVD_VARIABLES ""
set_interface_property in2 SVD_ADDRESS_GROUP ""

add_interface_port in2 asi_in2_data data Input 32
add_interface_port in2 asi_in2_valid valid Input 1


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

