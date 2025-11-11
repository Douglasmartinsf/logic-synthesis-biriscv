#-----------------------------------------------------------------------------
# SDC (Synopsys Design Constraints) for biRISC-V Core
# Target: GPDK045 (45nm)
# Generated: 2025/10/29
#-----------------------------------------------------------------------------

#################################################################################
## DEFINE VARS
#################################################################################
set sdc_version 1.5
current_design ${HDL_NAME}

#################################################################################
## IDEAL NETS (Clock and Reset)
#################################################################################
set_ideal_net [get_nets ${MAIN_CLOCK_NAME}]
set_ideal_net [get_nets ${MAIN_RST_NAME}]

#################################################################################
## CLOCK
#################################################################################
create_clock -name ${MAIN_CLOCK_NAME} -period $period_clk [get_ports ${MAIN_CLOCK_NAME}]
set_clock_uncertainty ${clk_uncertainty} [get_clocks ${MAIN_CLOCK_NAME}]
set_clock_latency ${clk_latency} [get_clocks ${MAIN_CLOCK_NAME}]

#################################################################################
## INPUT PINS (except clock)
#################################################################################
set_input_delay -clock [get_clocks ${MAIN_CLOCK_NAME}] ${in_delay} [remove_from_collection [all_inputs] "[get_ports ${MAIN_CLOCK_NAME}]"]

#################################################################################
## OUTPUT PINS
#################################################################################
set_output_delay -clock [get_clocks ${MAIN_CLOCK_NAME}] ${out_delay} [all_outputs]

#################################################################################
## OUTPUT PIN LOAD
#################################################################################
set_load -pin_load ${out_load} [get_ports [all_outputs]]

#################################################################################
## INPUT DRIVER (Slew rates)
#################################################################################
set_input_transition -rise -min $slew_min_rise [remove_from_collection [all_inputs] "[get_ports ${MAIN_CLOCK_NAME}]"]
set_input_transition -fall -min $slew_min_fall [remove_from_collection [all_inputs] "[get_ports ${MAIN_CLOCK_NAME}]"]

set_input_transition -rise -max $slew_max_rise [remove_from_collection [all_inputs] "[get_ports ${MAIN_CLOCK_NAME}]"]
set_input_transition -fall -max $slew_max_fall [remove_from_collection [all_inputs] "[get_ports ${MAIN_CLOCK_NAME}]"]

#################################################################################
## DESIGN RULES
#################################################################################
set_max_fanout 16 [current_design]
set_max_transition 0.5 [current_design]

#################################################################################
## OPTIMIZATION
#################################################################################
set_max_area 0

puts "SDC constraints loaded successfully"
puts "Clock period: ${period_clk} ns"
puts "Input delay: ${in_delay} ns"
puts "Output delay: ${out_delay} ns"

