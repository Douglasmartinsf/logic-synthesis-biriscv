###################################################
## Defining Variables
###################################################

# Design top name (Top module name and filename must be the same)
DESIGNS := riscv_core
export DESIGNS

# Username
USER := ufsm00290-figueiro202120243
export USER

## Hardware Description Language

## VHDL: HDL_LANG = vhdl
## SystemVerilog: HDL_LANG = sv
## Verilog: HDL_LANG = v2001 or HDL_LANG = v1995
HDL_LANG := v2001

# Validation
ifneq ($(filter $(HDL_LANG),vhdl sv v2001 v1995),$(HDL_LANG))
  $(error Valor invalido para HDL_LANG="$(HDL_LANG)". Use apenas: vhdl, sv, v2001 (default) ou v1995)
endif

export HDL_LANG

# Project directory (the top folder name should be the design name)
PROJECT_DIR := /home/ufsm00290/$(USER)/logic-synthesis-biriscv
export PROJECT_DIR

## Logic synthesis directory
SYNTHESIS_DIR := $(PROJECT_DIR)/synthesis
export SYNTHESIS_DIR

## Technology directory
TECH_DIR := /home/tools/design_kits/cadence/GPDK045/
export TECH_DIR

## HDL Name
HDL_NAME := $(DESIGNS)
export HDL_NAME

## If it is not specified in Command Line, Synthesis frequency is set to 100 MHz
FREQ_MHZ ?= 100
export FREQ_MHZ

## If it is not specified in Command Line, Corner is set to WORST (there ain't no typcal)
OP_CORNER ?= WORST

# Validation
ifneq ($(filter $(OP_CORNER),WORST BEST),$(OP_CORNER))
  $(error Valor invalido para OP_CORNER="$(OP_CORNER)". Use apenas: WORST ou BEST)
endif

export OP_CORNER


## File Extension
ifeq ($(HDL_LANG),vhdl)
  FILE_EXTENSION = vhd
else ifeq ($(HDL_LANG),sv)
  FILE_EXTENSION = sv
else ifeq ($(HDL_LANG),v2001)
  FILE_EXTENSION = v
else ifeq ($(HDL_LANG),v1995)
  FILE_EXTENSION = v
endif

export FILE_EXTENSION


## DUV Scope (VHDL must be different)
ifeq ($(HDL_LANG),vhdl)
  DUV_SCOPE = :DUV
else 
  DUV_SCOPE = ${DESIGNS}_tb/DUV
endif

export DUV_SCOPE

## If you want, you can add extra arguments for Xcelium execution
## Usefull for VHDL flgas (e.g -v200x -v93)
## Values should be written as an array of strings (e.g EXTRA_ARGS="-linedebug -coverage all -input test.do")

ifeq ($(HDL_LANG),vhdl)
  EXTRA_ARGS = "-v200x -v95"
endif

EXTRA_ARGS ?=

## Run Logic Synthesis
run-synth:
	./synthesis/scripts/run_first.tcl

## Compile SDF
compile-sdf:
	cd $(PROJECT_DIR)/synthesis/work && \
	xmsdfc -iocondsort  -compile $(PROJECT_DIR)/synthesis/deliverables/$(FREQ_MHZ)_MHz/$(OP_CORNER)/$(DESIGNS).sdf

## Simulation with no GUI (Customizada para Bubble Sort)
sim:
	mkdir -p $(PROJECT_DIR)/synthesis/work
	cd $(PROJECT_DIR)/synthesis/work && \
	xrun -clean && \
	cp $(PROJECT_DIR)/riscv-app-gen/bubblesort/bubblesort.bin tcm.bin && \
	xrun -v2001 -v93 \
		-F ../../src/core/filelist_xcelium.flist \
		../../tb/tb_core_icarus/tb_top.v \
		../../tb/tb_core_icarus/tcm_mem.v \
		../../tb/tb_core_icarus/tcm_mem_ram.v \
		../../tb/tb_core_icarus/biriscv_trace_sim_gls.sv \
		-incdir ../../src/core \
		-top tb_top \
		-timescale '1ns/1ps' \
		-access +rwc \
		+define+TRACE=1 \
		-input ../../monitor.tcl

## Simulation with GUI (Customizada para Bubble Sort)
sim-gui:
	mkdir -p $(PROJECT_DIR)/synthesis/work
	cd $(PROJECT_DIR)/synthesis/work && \
	xrun -clean && \
	cp $(PROJECT_DIR)/riscv-app-gen/bubblesort/bubblesort.bin tcm.bin && \
	xrun -v2001 -v93 \
		-F ../../src/core/filelist_xcelium.flist \
		../../tb/tb_core_icarus/tb_top.v \
		../../tb/tb_core_icarus/tcm_mem.v \
		../../tb/tb_core_icarus/tcm_mem_ram.v \
		../../tb/tb_core_icarus/biriscv_trace_sim_gls.sv \
		-incdir ../../src/core \
		-top tb_top \
		-timescale '1ns/1ps' \
		-access +rwc \
		+define+TRACE=1 \
		-gui \
		-input ../../waves.tcl

## Simulation with SDF notation (no GUI) - Customizada para Bubble Sort @ 185 MHz
sim-pos-syn:
	@if [ "$(OP_CORNER)" = "WORST" ]; then \
	  cd "$(PROJECT_DIR)/synthesis/work" && \
	  xrun -clean && \
	  cp $(PROJECT_DIR)/riscv-app-gen/bubblesort/bubblesort.bin tcm.bin && \
	  xrun -iocondsort $(EXTRA_ARGS) -mess -64bit -noneg_tchk  \
	    +define+TRACE=1 \
	    "$(TECH_DIR)/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v" \
	    "$(PROJECT_DIR)/synthesis/deliverables/$(FREQ_MHZ)_MHz/$(OP_CORNER)/$(DESIGNS).v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem_ram.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tb_top_postsyn.v" \
	    -top tb_top -timescale 1ns/1ps -access +rwc \
	    -input ../../monitor.tcl; \
	fi
	@if [ "$(OP_CORNER)" = "BEST" ]; then \
	  cd "$(PROJECT_DIR)/synthesis/work" && \
	  xrun -clean && \
	  cp $(PROJECT_DIR)/riscv-app-gen/bubblesort/bubblesort.bin tcm.bin && \
	  xrun -iocondsort $(EXTRA_ARGS) -mess -64bit -noneg_tchk \
	    +define+TRACE=1 \
	    "$(TECH_DIR)/gsclib045_all_v4.4/gsclib045/verilog/fast_vdd1v2_basicCells.v" \
	    "$(PROJECT_DIR)/synthesis/deliverables/$(FREQ_MHZ)_MHz/$(OP_CORNER)/$(DESIGNS).v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem_ram.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tb_top_postsyn.v" \
	    -top tb_top -timescale 1ns/1ps -access +rwc \
	    -input ../../monitor.tcl; \
	fi

## Simulation with SDF notation (with GUI) - Customizada para Bubble Sort @ 185 MHz
sim-pos-syn-gui:
	@if [ "$(OP_CORNER)" = "WORST" ]; then \
	  cd "$(PROJECT_DIR)/synthesis/work" && \
	  xrun -clean && \
	  cp $(PROJECT_DIR)/riscv-app-gen/bubblesort/bubblesort.bin tcm.bin && \
	  xrun -iocondsort $(EXTRA_ARGS) -mess -64bit -noneg_tchk \
	    +define+TRACE=1 \
	    "$(TECH_DIR)/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v" \
	    "$(PROJECT_DIR)/synthesis/deliverables/$(FREQ_MHZ)_MHz/$(OP_CORNER)/$(DESIGNS).v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem_ram.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tb_top_postsyn.v" \
	    -top tb_top  -timescale 1ns/1ps -access +rwc -gui \
	    -input ../../waves.tcl; \
	fi
	@if [ "$(OP_CORNER)" = "BEST" ]; then \
	  cd "$(PROJECT_DIR)/synthesis/work" && \
	  xrun -clean && \
	  cp $(PROJECT_DIR)/riscv-app-gen/bubblesort/bubblesort.bin tcm.bin && \
	  xrun -iocondsort $(EXTRA_ARGS) -mess -64bit -noneg_tchk \
	    +define+TRACE=1 \
	    "$(TECH_DIR)/gsclib045_all_v4.4/gsclib045/verilog/fast_vdd1v2_basicCells.v" \
	    "$(PROJECT_DIR)/synthesis/deliverables/$(FREQ_MHZ)_MHz/$(OP_CORNER)/$(DESIGNS).v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem_ram.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tcm_mem.v" \
	    "$(PROJECT_DIR)/tb/tb_core_icarus/tb_top_postsyn.v" \
	    -top tb_top -timescale 1ns/1ps -access +rwc -gui \
	    -input ../../waves.tcl; \
	fi

.PHONY: run-synth compile-sdf sim-pos-syn sim-pos-syn-gui sim sim-gui



RTL_DIR    = ../../src/core
TESTS_DIR  = ../../tb
TB         ?= 1
FLAGS += -access +rwc +define+TRACE=1 -input ../../monitor.tcl
ifeq ($(GUI),1)
	FLAGS += -gui -input ../../waves.tcl
endif

