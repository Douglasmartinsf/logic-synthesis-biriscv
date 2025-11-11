
#-----------------------------------------------------------------------------
# Create Library Domain
#-----------------------------------------------------------------------------
create_library_domain {worst best} 
get_db library_domains *


#-----------------------------------------------------------------------------
# LEF Files and Technology Library
#-----------------------------------------------------------------------------
set_db lib_search_path "${LIB_DIR} ${LEF_DIR}"
set_db [get_db library_domains worst] .library ${WORST_LIST}
set_db [get_db library_domains best] .library ${BEST_LIST}


#-----------------------------------------------------------------------------
# Operating conditions
#-----------------------------------------------------------------------------
get_db [get_db library_domains *worst] .operating_conditions
set_db [get_db library_domains *worst] .operating_conditions ${WORST_LIB_OPERATING_CONDITION}
get_db [get_db library_domains *worst] .operating_conditions
#--
get_db [get_db library_domains *best] .operating_conditions
set_db [get_db library_domains *best] .operating_conditions ${BEST_LIB_OPERATING_CONDITION}
get_db [get_db library_domains *best] .operating_conditions
#--
get_db [get_db library_domain *worst] .default
get_db [get_db library_domain *best] .default 
#--
get_db [vfind /libraries -library_domain worst] .active_operating_conditions
get_db [vfind /libraries -library_domain best] .active_operating_conditions 


#-----------------------------------------------------------------------------
# LEF, QRC and CAP Files
#-----------------------------------------------------------------------------

# Load lef files
set_db lef_library ${LEF_LIST}

# Load QRC tech files
set_db qrc_tech_file ${QRC_LIST}

# Use PLE mode for interconnect
get_db interconnect_mode
set_db interconnect_mode ple ;# global


#-----------------------------------------------------------------------------
# Manage Cells (Don't use scan flip-flops and latches)
#-----------------------------------------------------------------------------
get_lib_cells
get_db lib_cells *SDFF*
get_db base_cell:SDFFRHQX1 .dont_use
set_db base_cell:SDFFRHQX1 .dont_use true

foreach lc [get_db base_cells -if {.name == "SDFF*"}] {
  get_db $lc .dont_use
  set_db $lc .dont_use true
}

foreach lc [get_db base_cells -if {.name == "TLATS*"}] {
  get_db $lc .dont_use
  set_db $lc .dont_use true
}

if { $OP_CORNER eq "WORST" } {
    puts "\n Setting WORST LIB! \n"
    set_db [get_db library_domain *worst] .default true
} else {
    puts "\n Setting BEST LIB! \n"
    set_db [get_db library_domain *best] .default true
}


#-----------------------------------------------------------------------------
# Report important info
#-----------------------------------------------------------------------------
get_db [get_db library_sets *worst] .libraries
get_db [get_db library_sets *best] .libraries
get_db [get_db library_sets *worst] .libraries.lib_cells
get_db [get_db library_sets *best] .libraries.lib_cells
