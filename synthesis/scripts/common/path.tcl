
#-----------------------------------------------------------------------------
# Common path variables (directory structure dependent)
#-----------------------------------------------------------------------------
set SYNT_DIR ${PROJECT_DIR}/synthesis
set SCRIPT_DIR ${SYNT_DIR}/scripts
set RPT_DIR ${SYNT_DIR}/reports
set DEV_DIR ${SYNT_DIR}/deliverables

#-----------------------------------------------------------------------------
# Setting RTL search directories
#-----------------------------------------------------------------------------
set SRC_DIR ${PROJECT_DIR}/src
set CORE_DIR ${SRC_DIR}/core
set OTHERS ""
lappend SRC_DIR $OTHERS

#-----------------------------------------------------------------------------
# Setting technology directories
#-----------------------------------------------------------------------------
set LIB_DIR ${TECH_DIR}/gsclib045_svt_v4.4/gsclib045/timing
#lappend LIB_DIR ${TECH_DIR}/io

set LEF_DIR ${TECH_DIR}/gsclib045_svt_v4.4/gsclib045/lef
lappend LEF_DIR ${TECH_DIR}/giolib045_v3.3/lef
