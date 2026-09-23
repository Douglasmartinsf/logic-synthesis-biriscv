# Synthesis Evidence Index

[Back to the case study](../../README.md) · [Execution guide](../README.md)

This directory contains one published report set: [`baseline/170_MHz/WORST`](baseline/170_MHz/WORST). The `baseline` name is retained from the archive; an exact source revision and complete run manifest were not recorded with these reports. They should not be treated as measurements of the current ALU implementation without that provenance.

## Published reference run

| Item | Archived value | Evidence |
| --- | --- | --- |
| Design | `riscv_core` | [QoR header](baseline/170_MHz/WORST/riscv_core_qor.rpt) |
| Tool | Genus 21.19-s055_1 | [QoR header](baseline/170_MHz/WORST/riscv_core_qor.rpt) |
| Generation date | December 2, 2025 | [QoR header](baseline/170_MHz/WORST/riscv_core_qor.rpt) |
| Run label | `baseline / 170_MHz / WORST` | [Directory](baseline/170_MHz/WORST) |
| Clock period | 5,880 ps = 5.88 ns | [Timing](baseline/170_MHz/WORST/riscv_core_timing.rpt) |
| Critical-path setup slack | 0 ps; MET | [Timing](baseline/170_MHz/WORST/riscv_core_timing.rpt) |
| Total negative slack / violating paths | 0 / 0 | [QoR](baseline/170_MHz/WORST/riscv_core_qor.rpt) |
| Leaf instances | 26,708 | [QoR](baseline/170_MHz/WORST/riscv_core_qor.rpt) |
| Sequential / combinational instances | 2,870 / 23,838 | [QoR](baseline/170_MHz/WORST/riscv_core_qor.rpt) |
| Cell area | 82,238.688, in report/library area units | [Area](baseline/170_MHz/WORST/riscv_core_area.rpt) |
| Net area | 33,741.056, in report/library area units | [Area](baseline/170_MHz/WORST/riscv_core_area.rpt) |
| Total cell + net area | 115,979.744, in report/library area units | [Area](baseline/170_MHz/WORST/riscv_core_area.rpt) |
| Estimated total power | 2,806.67 µW ≈ 2.807 mW | [Power](baseline/170_MHz/WORST/riscv_core_power.rpt) |

The timing report shows a setup path from `u_frontend_u_decode_genblk1.u_fifo_rd_ptr_q_reg[0]` to `u_exec0_result_q_reg[31]`. It reports a 5,730 ps data path and zero setup slack. This supports the narrow conclusion that this path met the archived constraint at the report's precision, without reported timing margin.

### Interpretation limits

- **Frequency:** 170 MHz is the run label/target. The script rounds its clock period; the report is not a frequency sweep establishing maximum operating frequency.
- **Conditions:** the directory is labeled `WORST`, but report headers list both `PVT_0P9V_125C` and `PVT_1P32V_0C`. The area report lists both `slow_vdd1v0` and `fast_vdd1v2` library domains. Keep those facts visible instead of assigning every reported value to one independently verified PVT condition.
- **Area:** the text report does not explicitly state an area unit. Values are reproduced as report/library units rather than relabeled as µm² without library confirmation. Total area includes a net-area estimate and is not die area.
- **Power:** the report explicitly uses µW, but does not identify the stimulus workload or activity-annotation coverage. Treat it as a tool estimate, not measured silicon power or a confirmed Bubble Sort power result. The current synthesis script's VCD flag is not accompanied by a VCD-loading command.
- **Provenance:** the report generation date and folder name do not establish which RTL revision, parameter overrides, or script revision produced the run.
- **Verification:** setup timing and QoR reports do not establish functional equivalence, complete timing signoff, post-route performance, or application throughput.

## Other frequency references

| Reference | Available evidence | How it is used |
| --- | --- | --- |
| 185 MHz | The current [`tb_top.v`](../../tb/tb_core_icarus/tb_top.v) has a fixed clock and SDF path for this setting | Describes the simulation configuration; not a published timing-closure result |
| 190 MHz | [Commit `9277d29`](https://github.com/Douglasmartinsf/logic-synthesis-biriscv/commit/9277d29975fc4d6d4b83ca0d0025959fd54ada8f) records this frequency alongside pipeline changes | Historical result recorded in a commit message; supporting report set is absent from the current tree |

The prior index described additional frequencies and optimization directories, but their report sets are not present in the current tree. There is no published matched ALU/shifter before/after pair here. Consequently, this case study does not calculate a frequency uplift, area reduction, or performance gain from these mixed references.

The current core and frontend default `EXTRA_DECODE_STAGE` to `0`. A historical pipeline experiment must not be assumed to describe the current default configuration.

## Report navigation

| Report | What to inspect |
| --- | --- |
| [Timing](baseline/170_MHz/WORST/riscv_core_timing.rpt) | Critical path, required/arrival times, slack |
| [Timing lint](baseline/170_MHz/WORST/riscv_core_timing_lint.rpt) | Constraint diagnostics and coverage |
| [QoR](baseline/170_MHz/WORST/riscv_core_qor.rpt) | Summary of timing, instances, and area |
| [Area](baseline/170_MHz/WORST/riscv_core_area.rpt) / [Detailed area](baseline/170_MHz/WORST/riscv_core_area_detail.rpt) | Hierarchical area and cell counts |
| [Gates](baseline/170_MHz/WORST/riscv_core_gates.rpt) | Cell usage |
| [Power](baseline/170_MHz/WORST/riscv_core_power.rpt) | Leakage, internal, switching, and total estimated power |
| [Hierarchy](baseline/170_MHz/WORST/riscv_core_hierarchy.rpt) | Synthesized design hierarchy |

## Evidence needed for a future comparison

A reproducible ALU comparison needs two identified RTL revisions with matching core parameters, tool version, libraries, operating conditions, and constraints. Preserve the complete timing/area/QoR reports for each run, together with any power activity setup. Change only the ALU/shifter for an isolated comparison, or explicitly describe other differences.

Functional checks should cover logical and arithmetic shifts, negative operands, boundary shift amounts, and integration into the processor before claiming that a timing improvement preserves behavior. Archive the verification method and results alongside the synthesis reports. These are requirements for a future experiment, not tests claimed to have passed here.
