cd [file normalize [file dirname [info script]]]
create_project uart_arty_a7_100t ./uart_arty_a7_100t -part xc7a100ticsg324-1L -force
set_msg_config -suppress -id {Synth 8-7080}
set_msg_config -suppress -id {Power 33-332}
set_msg_config -suppress -id {Pwropt 34-321}
set_msg_config -suppress -id {Synth 8-6841}
set_msg_config -suppress -id {Netlist 29-101}
set_property simulator_language Verilog [current_project]
add_files -fileset constrs_1 -norecurse { ./uart_arty_a7_constraints.xdc }
add_files -norecurse .
add_files -norecurse { ../../../../hardware/mcu/ }
add_files -norecurse { ../../software/build/uart_demo.hex }
set_property file_type {Memory Initialization Files} [get_files ../../software/build/uart_demo.hex]