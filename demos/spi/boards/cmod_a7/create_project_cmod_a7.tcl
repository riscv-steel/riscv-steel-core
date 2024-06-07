cd [file normalize [file dirname [info script]]]
create_project spi_cmod_a7_35t ./spi_cmod_a7_35t -part xc7a35tcpg236-1 -force
set_msg_config -suppress -id {Synth 8-7080}
set_msg_config -suppress -id {Power 33-332}
set_msg_config -suppress -id {Pwropt 34-321}
set_msg_config -suppress -id {Synth 8-6841}
set_msg_config -suppress -id {Netlist 29-101}
set_property simulator_language Verilog [current_project]
add_files -fileset constrs_1 -norecurse { ./spi_cmod_a7_constraints.xdc }
add_files -norecurse .
add_files -norecurse { ../../../../hardware/mcu/ }
add_files -norecurse { ../../software/build/spi_demo.hex }
set_property file_type {Memory Initialization Files} [get_files ../../software/build/spi_demo.hex]