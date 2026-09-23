# Synthesis and Simulation Guide

[Back to the case study](../README.md) · [Archived results](reports_versions/README.md)

This guide describes the checked-in biRISC-V flow: **Cadence Genus with GPDK045**, plus Xcelium/SimVision simulation targets. The scripts contain site-specific paths and fixed testbench settings; commands below require the stated local setup. They have been checked against the source, not rerun as part of the documentation update.

## Requirements

| Task | Requirements |
| --- | --- |
| Read the results | A text viewer; the archived reports are committed |
| Synthesize the core | Linux, Bash, GNU Make, licensed Cadence Genus, and the expected local GPDK045 libraries |
| Build a test application | `riscv64-unknown-elf-gcc`, `objcopy`, `objdump`, and `readelf`, with RV32IM / ILP32 support |
| Run the root simulation targets | Cadence Xcelium (`xrun`); SimVision for GUI inspection |
| Run gate-level simulation | Matching mapped netlist, SDF, technology cell models, and application binary |

The PDK, Cadence tools, and generated netlist/SDF are not included in the current repository tree.

## Flow and configuration

The root [Makefile](../Makefile) exports configuration to the [launcher](scripts/run_first.tcl) and [Genus script](scripts/riscv_core.tcl). Despite its `.tcl` suffix, the launcher is a Bash script. Genus reads the RTL, elaborates `riscv_core`, applies the [SDC constraints](constraints/riscv_core.sdc), performs generic synthesis and technology mapping, then runs incremental optimization and writes reports, netlist, and SDF.

| Make variable | Current default | Meaning |
| --- | --- | --- |
| `PROJECT_DIR` | A site-specific absolute path | Override with the repository's absolute path |
| `TECH_DIR` | A site-specific GPDK045 path | Override with the local technology installation |
| `DESIGNS` | `riscv_core` | Top-level design and script basename |
| `HDL_LANG` | `v2001` | Language used for the processor RTL |
| `FREQ_MHZ` | `100` | Synthesis target; period is rounded to two decimal places in ns |
| `OP_CORNER` | `WORST` | Accepts `WORST` or `BEST` |

Pass path overrides on the `make` command line: shell environment values alone do not override the Makefile's ordinary assignments. Use paths without spaces, since the existing scripts do not consistently quote paths.

### Local technology layout

Inspect [path.tcl](scripts/common/path.tcl), [tech.tcl](scripts/common/tech.tcl), and [riscv_core.tcl](scripts/riscv_core.tcl) before running. The flow expects:

- Timing and LEF files beneath `gsclib045_svt_v4.4/gsclib045`, plus the configured I/O LEF directory.
- `slow_vdd1v0_basicCells.lib` and `fast_vdd1v2_basicCells.lib`, with operating-condition identifiers configured in the main script.
- QRC data beneath `gpdk045_v_6_0/qrc/rcworst`.
- Simulation cell models beneath `gsclib045_all_v4.4/gsclib045/verilog`, as referenced by the Makefile.

Both library domains are loaded. `OP_CORNER` selects the default domain, while the QRC path remains set to `rcworst`. Check the selected libraries and operating conditions in each new run's logs; changing the corner label is not a complete multi-corner signoff flow.

## Run synthesis

From the repository root in a configured Linux shell:

```bash
export PROJECT_DIR="$PWD"
export TECH_DIR="/path/to/GPDK045"

# The launcher changes into this directory before starting Genus.
mkdir -p "$PROJECT_DIR/synthesis/work"

# The checked-in launcher needs executable permission for this target.
chmod u+x synthesis/scripts/run_first.tcl

make run-synth PROJECT_DIR="$PROJECT_DIR" TECH_DIR="$TECH_DIR" \
  FREQ_MHZ=170 OP_CORNER=WORST
```

Replace the technology path with the actual installation. There is no `make setup` target in the current Makefile. The Genus script creates report and deliverable directories after elaboration; the working directory must already exist.

This runs the **current RTL** at the requested target. It does not reconstruct the archived `baseline` run: that archive does not specify its exact source revision.

### Constraints in the current scripts

| Setting | Current value / behavior |
| --- | --- |
| Top-level clock / reset port names | `clk` / `rst_n` |
| Period | `1000 / FREQ_MHZ`, formatted to two decimal places in ns |
| Clock uncertainty / latency | 0.05 ns / 0.10 ns |
| Input / output delay | Fixed 0.30 ns / 0.30 ns, not a percentage of the period |
| Output load | 0.045 pF as annotated in the main script |
| Input transition, min rise / fall | 0.146 ns / 0.164 ns |
| Input transition, max rise / fall | 0.264 ns / 0.252 ns |
| Initial design rules | Maximum fanout 16; maximum transition 0.5 ns |
| Additional post-map constraints | Maximum fanout 10 on inputs; maximum transition 0.15 ns on the design |
| Clock and reset nets | Marked ideal in the SDC; no reset false-path command is present |

The reset name alone is not a polarity specification: the current testbench drives reset high, then releases it low. Preserve the RTL/testbench behavior when interpreting this flow rather than inferring active-low behavior from `rst_n`.

The HDL list excludes the simulation trace module and the Xilinx-specific register-file implementation. The script preserves the multiplier and divider hierarchy while permitting other ungrouping.

### Generated outputs

| Output path, relative to the repository | Contents |
| --- | --- |
| `synthesis/work/` | Tool working files and logs |
| `synthesis/reports/<FREQ>_MHz/<CORNER>/` | Timing, timing-lint, area, detailed area, gates, QoR, power, and hierarchy reports |
| `synthesis/deliverables/<FREQ>_MHz/<CORNER>/` | `riscv_core.v` mapped netlist and `riscv_core.sdf` |

The committed evidence lives separately in [`reports_versions`](reports_versions/README.md). A new local run does not update that archive automatically.

## Build an application

The [application Makefile](../riscv-app-gen/Makefile) uses a bare-metal `riscv64-unknown-elf-` toolchain with `-march=rv32im -mabi=ilp32`:

```bash
cd riscv-app-gen
make SRC=bubblesort/bubblesort.c
make info SRC=bubblesort/bubblesort.c
cd ..
```

The build emits `.elf`, `.bin`, and disassembly `.s` beside the source. Its linker settings use `main` as the entry point and `-nostartfiles`. Check the ELF entry address, memory placement, and stack/startup assumptions when changing the application or toolchain. The testbench has a fixed `reset_vector_i` of `0x80000054`; it does not automatically read the ELF entry point. The root simulation targets copy the Bubble Sort binary to `tcm.bin`.

## Simulation targets and alignment

The root Makefile exposes the following targets:

| Target | Purpose |
| --- | --- |
| `sim` / `sim-gui` | RTL simulation, with optional GUI |
| `compile-sdf` | Compile the SDF using `xmsdfc` |
| `sim-pos-syn` / `sim-pos-syn-gui` | Gate-level simulation, with optional GUI |

Each target uses `PROJECT_DIR` and `TECH_DIR`; supply the same path overrides as for synthesis. For example, **after aligning the inputs below**, the existing WORST-corner gate-level setup is invoked with:

```bash
make sim-pos-syn PROJECT_DIR="$PROJECT_DIR" TECH_DIR="$TECH_DIR" \
  FREQ_MHZ=185 OP_CORNER=WORST
```

Before interpreting a run, align these fixed settings in [`tb_top.v`](../tb/tb_core_icarus/tb_top.v) with the generated artifacts:

1. **Clock:** the half-period is hardcoded to `2.7027` ns, approximately 185 MHz. `FREQ_MHZ` does not change it.
2. **SDF:** under `POSTSYN`, the testbench annotates `../deliverables/185_MHz/WORST/riscv_core.sdf`, with the `TYPICAL` SDF value selection. The path is independent of Makefile variables; the SDF value selection and library corner are separate settings.
3. **Netlist and models:** the Makefile chooses their paths using `FREQ_MHZ`, `OP_CORNER`, and `TECH_DIR`. They must correspond to the SDF and intended run.
4. **Application:** the binary, entry address, and memory/startup assumptions must agree. The existing bench dumps memory; it is not an automated Bubble Sort pass/fail checker.
5. **Simulation defines:** the current `BEST` GUI gate-level recipe omits `POSTSYN`, so that recipe does not enable this testbench's conditional SDF annotation as written.

The 185 MHz command requires a matching local synthesis output. The archived 170 MHz reports do not supply a usable 185 MHz netlist or SDF. Review simulator warnings, annotation coverage, and the expected application output before claiming a successful gate-level test.

The directory name `tb_core_icarus` is historical; the root targets described here invoke Cadence Xcelium. Its separate Icarus Makefile is not presented here as a verified alternative.

## Reading the results

- **Timing and QoR:** check slack, violating paths, constrained endpoints, and the timing-lint report. A higher requested frequency alone is not a successful result.
- **Area:** distinguish cell area from estimated net area; neither is a measured die area.
- **Power:** record the activity source and conditions. `USE_VCD_POWER_ANALYSIS` is assigned in the script, but the current script has no command that reads a VCD; that variable alone does not establish activity-based power analysis.
- **Comparisons:** record the RTL revision, parameters, tool version, libraries, constraints, and verification results for both runs. See the [evidence index](reports_versions/README.md) for the available archive and its gaps.

These instructions document the existing flow and its limitations. No new synthesis, timing closure, or functional verification is claimed by this documentation update.
