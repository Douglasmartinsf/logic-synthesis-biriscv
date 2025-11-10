# biRISC-V Core Synthesis Script
# Adapted for Cadence Genus
# Last update: 2025/10/29

puts "=========================================="
puts "  biRISC-V Core Logic Synthesis"
puts "=========================================="

#-----------------------------------------------------------------------------
# Main Custom Variables Design Dependent
#-----------------------------------------------------------------------------
set PROJECT_DIR $env(PROJECT_DIR)
set TECH_DIR $env(TECH_DIR)
set DESIGNS $env(DESIGNS)
set HDL_NAME $env(HDL_NAME)
set INTERCONNECT_MODE ple
set OP_CORNER $env(OP_CORNER)
set HDL_LANG $env(HDL_LANG)
set USE_VCD_POWER_ANALYSIS 0

set freq_mhz $env(FREQ_MHZ)

#-----------------------------------------------------------------------------
# MAIN Custom Variables for SDC (constraints file)
#-----------------------------------------------------------------------------
set MAIN_CLOCK_NAME clk
set MAIN_RST_NAME rst_n
set BEST_LIB_OPERATING_CONDITION PVT_1P32V_0C
set WORST_LIB_OPERATING_CONDITION PVT_0P9V_125C
set period_clk [format "%.2f" [expr 1000.0 / $freq_mhz]] ;# ns
set clk_uncertainty 0.05 ;# ns
set clk_latency 0.10 ;# ns
set in_delay 0.30 ;# ns (fixed value, NOT percentage of period!)
set out_delay 0.30 ;# ns (fixed value, NOT percentage of period!)
set out_load 0.045 ;# pF
set slew_min_rise 0.146 ;# ns
set slew_min_fall 0.164 ;# ns
set slew_max_rise 0.264 ;# ns
set slew_max_fall 0.252 ;# ns

# Technology libraries
set WORST_LIST {slow_vdd1v0_basicCells.lib} 
set BEST_LIST {fast_vdd1v2_basicCells.lib} 
set LEF_LIST {gsclib045_tech.lef gsclib045_macro.lef}
set WORST_CAP_LIST ${TECH_DIR}/gpdk045_v_6_0/soce/gpdk045.basic.CapTbl
set QRC_LIST ${TECH_DIR}/gpdk045_v_6_0/qrc/rcworst/qrcTechFile

puts "Frequency: ${freq_mhz} MHz (Period: ${period_clk} ns)"
puts "Corner: ${OP_CORNER}"

#-----------------------------------------------------------------------------
# Load Path File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/synthesis/scripts/common/path.tcl

#-----------------------------------------------------------------------------
# Load Tech File
#-----------------------------------------------------------------------------
source ${SCRIPT_DIR}/common/tech.tcl

#-----------------------------------------------------------------------------
# Analyze RTL source (biRISC-V core modules)
# IMPORTANTE: biriscv_trace_sim.v NÃO É SINTETIZÁVEL (apenas para simulação)
# IMPORTANTE: biriscv_xilinx_2r1w.v é específico para Xilinx (não usar em ASIC)
#-----------------------------------------------------------------------------
set_db init_hdl_search_path "${SRC_DIR} ${CORE_DIR}"

puts "Reading biRISC-V RTL files..."

# Ler todos os arquivos juntos para que defines sejam propagados globalmente
# Ordem: definições primeiro, depois módulos básicos, depois hierarquia
read_hdl -language ${HDL_LANG} \
    biriscv_defs.v \
    biriscv_alu.v \
    biriscv_alu_pipelined.v \
    biriscv_csr_regfile.v \
    biriscv_csr.v \
    biriscv_decoder.v \
    biriscv_decode.v \
    biriscv_divider.v \
    biriscv_multiplier.v \
    biriscv_exec.v \
    biriscv_npc.v \
    biriscv_fetch.v \
    biriscv_frontend.v \
    biriscv_lsu.v \
    biriscv_mmu.v \
    biriscv_pipe_ctrl.v \
    biriscv_regfile.v \
    biriscv_issue.v \
    riscv_core.v

# NÃO incluir:
# - biriscv_trace_sim.v (não sintetizável - apenas debug)
# - biriscv_xilinx_2r1w.v (específico Xilinx FPGA)

puts "RTL files read successfully"

#-----------------------------------------------------------------------------
# Elaborate Design
#-----------------------------------------------------------------------------
puts "Elaborating design..."
elaborate ${HDL_NAME}
set_top_module ${HDL_NAME}
check_design -unresolved ${HDL_NAME}
get_db current_design
check_library

puts "Design elaborated: ${HDL_NAME}"

#-----------------------------------------------------------------------------
# Create output directories (ANTES de ler constraints)
#-----------------------------------------------------------------------------
file mkdir ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}
file mkdir ${DEV_DIR}/${freq_mhz}_MHz/${OP_CORNER}

#-----------------------------------------------------------------------------
# Constraints
#-----------------------------------------------------------------------------
puts "Reading constraints..."
read_sdc ${PROJECT_DIR}/synthesis/constraints/${HDL_NAME}.sdc
report timing -lint
report_timing -lint > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_timing_lint.rpt

#-----------------------------------------------------------------------------
# Post-Elaborate Attributes
#-----------------------------------------------------------------------------
set_db auto_ungroup both ;# Allow ungrouping for optimization

# IMPORTANTE: Preservar hierarquia de multiplicador e divisor para melhor timing
# Esses módulos têm caminhos críticos que se beneficiam de otimização isolada
set_db hinst:riscv_core/u_mul .ungroup_ok false
set_db hinst:riscv_core/u_div .ungroup_ok false

#-----------------------------------------------------------------------------
# Generic optimization (technology independent)
#-----------------------------------------------------------------------------
puts "Running generic synthesis..."
syn_generic ${HDL_NAME}

#-----------------------------------------------------------------------------
# Technology mapping and optimization
#-----------------------------------------------------------------------------
puts "Running technology mapping..."
syn_map ${HDL_NAME}
get_db insts .base_cell.name -u ;# List all cell names used

#-----------------------------------------------------------------------------
# Generate reports and output files
#-----------------------------------------------------------------------------
puts "Generating reports..."
report_design_rules
report_area -detail > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_area_detail.rpt
report_area > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_area.rpt
report_timing > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_timing.rpt
report_gates > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_gates.rpt
report_qor > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_qor.rpt
report_power -unit uW > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_power.rpt
report_hierarchy > ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}_hierarchy.rpt

puts "Writing netlist and SDF..."
# Load SDF width workaround
source ${SCRIPT_DIR}/common/sdf_width_wa.etf

write_sdf -edge check_edge -setuphold merge_always -nonegchecks -recrem merge_always -version 3.0 -design ${HDL_NAME} > ${DEV_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}.sdf
write_hdl ${HDL_NAME} > ${DEV_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}.v

puts "=========================================="
puts "  Synthesis Complete!"
puts "  Netlist: ${DEV_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}.v"
puts "  SDF: ${DEV_DIR}/${freq_mhz}_MHz/${OP_CORNER}/${HDL_NAME}.sdf"
puts "  Reports: ${RPT_DIR}/${freq_mhz}_MHz/${OP_CORNER}/"
puts "=========================================="
