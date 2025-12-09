# Estrutura do Projeto biRISC-V - Logic Synthesis

Este documento descreve a estrutura completa de diretórios e arquivos do projeto de síntese lógica do processador biRISC-V usando **Cadence Genus** para síntese e **Cadence Xcelium SimVision** para simulação.

---

## 📁 Estrutura de Diretórios

```
logic-synthesis-biriscv/
├── docs/                          # Documentação
├── riscv-app-gen/                 # Aplicações RISC-V de teste
├── scripts/                       # Scripts auxiliares
├── src/                           # Código-fonte RTL (Verilog)
│   ├── core/                      # Módulos do processador biRISC-V
│   ├── dcache/                    # Data cache
│   ├── icache/                    # Instruction cache
│   ├── tcm/                       # Tightly Coupled Memory
│   └── top/                       # Top-level wrappers
├── synthesis/                     # Síntese lógica com Cadence Genus
│   ├── scripts/                   # Scripts TCL de síntese
│   ├── constraints/               # Timing constraints (SDC)
│   ├── work/                      # Diretório de trabalho do Genus
│   ├── reports/                   # Relatórios de síntese
│   └── deliverables/              # Netlist e SDF gerados
└── tb/                            # Testbenches
    ├── tb_core_icarus/            # Testbench simplificado (RTL/GLS)
    ├── tb_tcm/                    # Testbench com TCM
    └── tb_top/                    # Testbench completo (SystemC/Verilator)
```

---

## 📄 Arquivos na Raiz

| Arquivo | Descrição |
|---------|-----------|
| **Makefile** | Makefile principal com targets para síntese (`run-synth`), simulação RTL (`sim`, `sim-gui`) e simulação gate-level (`sim-pos-syn`, `sim-pos-syn-gui`) usando **Cadence Xcelium** |
| **README.md** | Documentação geral do projeto, features do biRISC-V, instruções de uso |
| **LICENSE** | Licença do projeto (Apache 2.0 do biRISC-V original) |
| **waves.tcl** | Script TCL para **Cadence SimVision** - configura waveform automaticamente com sinais essenciais (clock, reset, PC, instruções, memória) |
| **monitor.tcl** | Script TCL para **SimVision** - executa simulação com monitoramento de progresso (50 passos de 100µs cada) |
| **debug_loop.tcl** | Script TCL para **SimVision** - executa simulação com timeout de 5ms para evitar loops infinitos |
| **.gitignore** | Lista de arquivos/diretórios ignorados pelo Git (work/, deliverables/, etc) |

---

## 📚 docs/ - Documentação

| Arquivo | Descrição |
|---------|-----------|
| **configuration.md** | Documentação de parâmetros de configuração do biRISC-V (branch prediction, cache sizes, pipeline stages) |
| **custom.md** | Guia para customização do core (adicionar instruções, modificar pipeline) |
| **integration.md** | Guia de integração do biRISC-V em sistemas maiores (AXI, Wishbone) |
| **linux.md** | Instruções para rodar Linux no biRISC-V |
| **biRISC-V.png** | Diagrama de arquitetura do processador dual-issue |
| **dual_issue.png** | Diagrama mostrando execução de 2 instruções por ciclo |
| **linux-boot.png** | Screenshot do Linux bootando no biRISC-V |
| **gls_sim_vision_bubble.png** | Screenshot da simulação gate-level do bubblesort no **SimVision** |
| **riscv_isa_spec.pdf** | Especificação ISA RISC-V v2.1 (base) |
| **riscv_privileged_spec.pdf** | Especificação RISC-V privileged v1.11 (CSR, traps, MMU) |

---

## 🧮 riscv-app-gen/ - Aplicações RISC-V

Diretório com aplicações C compiladas para RISC-V RV32IM usando **riscv-gnu-toolchain**.

| Arquivo/Diretório | Descrição |
|-------------------|-----------|
| **Makefile** | Compila aplicações C para binários RISC-V (.elf, .bin, .s) usando `riscv32-unknown-elf-gcc` |
| **link.ld** | Linker script - define layout de memória (entry point 0x80000000, seções .text/.data/.bss) |

### Aplicações Disponíveis:

| Diretório | Descrição |
|-----------|-----------|
| **bubblesort/** | Bubble sort de array {5,4,3,2,1,0,3} → {0,1,2,3,3,4,5} |
| **quicksort/** | Quick sort (recursivo) |
| **dot_product/** | Produto escalar de dois vetores |
| **array_sum_mul/** | Soma e multiplicação de elementos de array |
| **swap_bits/** | Troca de bits em palavra de 32 bits |
| **insertion_sort/** | Insertion sort |
| **original_test_code/** | Código assembly de teste original (.s) |

**Arquivos em cada subdiretório:**
- `*.c` - Código-fonte C
- `*.s` - Assembly gerado pelo gcc
- `*.elf` - Executável ELF (usado em simulação)
- `*.bin` - Binário puro (carregado em memória do testbench)

---

## 🛠️ scripts/ - Scripts Auxiliares

| Arquivo | Descrição |
|---------|-----------|
| **sync_to_server.ps1** | Script PowerShell para transferir arquivos modificados localmente (Windows) para servidor remoto via `scp` e converter line endings (CRLF→LF) |

---

## 💻 src/ - Código-fonte RTL (Verilog 2001)

### src/core/ - Processador biRISC-V (17 módulos sintetizáveis)

| Arquivo | Módulo | Descrição |
|---------|--------|-----------|
| **biriscv_defs.v** | N/A | **Defines globais** - opcodes, ALU ops, CSR addresses, configurações (SUPPORT_MULDIV, etc). **Ler primeiro na síntese!** |
| **riscv_core.v** | `riscv_core` | **Top module** - instancia todos submódulos (frontend, issue, exec, LSU, regfile, CSR, MMU) |
| **biriscv_frontend.v** | `biriscv_frontend` | **Frontend** - fetch + branch prediction (bimodal/gshare) + BTB + RAS. Controla `EXTRA_DECODE_STAGE` |
| **biriscv_fetch.v** | `biriscv_fetch` | **Instruction fetch** - busca instruções de 64 bits, PC increment, alinha instruções |
| **biriscv_decode.v** | `biriscv_decode` | **Decode stage** - decodifica instruções, gera sinais de controle |
| **biriscv_decoder.v** | `biriscv_decoder` | **Instruction decoder** - tabela de decodificação (opcode → ALU op, branch type, etc) |
| **biriscv_issue.v** | `biriscv_issue` | **Dual-issue logic** - seleciona até 2 instruções independentes por ciclo para execução paralela |
| **biriscv_exec.v** | `biriscv_exec` | **Execution stage** - coordena ALU, multiplicador, divisor, branch/jump |
| **biriscv_alu.v** | `biriscv_alu` | **ALU** - operações aritméticas, lógicas, shifts (barrel shifter otimizado), comparações. Pipelined em 2 estágios |
| **biriscv_multiplier.v** | `biriscv_multiplier` | **Multiplicador** - 32x32 → 64 bits (MUL, MULH, MULHSU, MULHU) |
| **biriscv_divider.v** | `biriscv_divider` | **Divisor** - divisão/resto (DIV, DIVU, REM, REMU). Iterativo, multi-ciclo |
| **biriscv_lsu.v** | `biriscv_lsu` | **Load/Store Unit** - acesso à memória de dados (LB, LH, LW, SB, SH, SW), detecção de misalignment. Registra `mem_error_i` |
| **biriscv_npc.v** | `biriscv_npc` | **Next PC logic** - calcula próximo PC (sequencial, branch, jump, trap) |
| **biriscv_regfile.v** | `biriscv_regfile` | **Register file** - 32 registradores x 32 bits (x0 hardwired a zero), 2 read ports, 2 write ports (dual-issue) |
| **biriscv_csr.v** | `biriscv_csr` | **CSR controller** - lógica de acesso a CSRs (CSRRW, CSRRS, CSRRC), traps, interrupts |
| **biriscv_csr_regfile.v** | `biriscv_csr_regfile` | **CSR register file** - registradores de controle (mstatus, mtvec, mepc, mcause, etc) |
| **biriscv_mmu.v** | `biriscv_mmu` | **MMU** - Memory Management Unit básico (TLB, page table walk) para rodar Linux |
| **biriscv_pipe_ctrl.v** | `biriscv_pipe_ctrl` | **Pipeline control** - hazard detection, forwarding, stalls, flushes |

**Arquivos NÃO sintetizáveis (apenas simulação):**

| Arquivo | Descrição |
|---------|-----------|
| **biriscv_trace_sim.v** | Monitor de debug - imprime instruções executadas, registradores alterados (apenas simulação RTL) |
| **biriscv_xilinx_2r1w.v** | Register file para FPGA Xilinx (usa primitivas BRAM) - não usado em ASIC |
| **filelist_xcelium.flist** | Lista de arquivos para **Cadence Xcelium** - ordem correta para compilação |

---

### src/dcache/ - Data Cache

| Arquivo | Módulo | Descrição |
|---------|--------|-----------|
| **dcache.v** | `dcache` | Top-level do data cache |
| **dcache_core.v** | `dcache_core` | Lógica principal do cache (tag compare, hit/miss) |
| **dcache_core_data_ram.v** | `dcache_data_ram` | RAM de dados do cache |
| **dcache_core_tag_ram.v** | `dcache_tag_ram` | RAM de tags do cache |
| **dcache_if_pmem.v** | `dcache_if_pmem` | Interface para memória externa |
| **dcache_mux.v** | `dcache_mux` | Multiplexador de acessos |
| **dcache_pmem_mux.v** | `dcache_pmem_mux` | Multiplexador de memória externa |
| **dcache_axi.v** | `dcache_axi` | Wrapper AXI4 para o cache |
| **dcache_axi_axi.v** | `dcache_axi_axi` | Adaptador AXI-to-AXI |

---

### src/icache/ - Instruction Cache

| Arquivo | Módulo | Descrição |
|---------|--------|-----------|
| **icache.v** | `icache` | Instruction cache (fetch de 64 bits) |
| **icache_data_ram.v** | `icache_data_ram` | RAM de dados (instruções) |
| **icache_tag_ram.v** | `icache_tag_ram` | RAM de tags |

---

### src/tcm/ - Tightly Coupled Memory

| Arquivo | Módulo | Descrição |
|---------|--------|-----------|
| **tcm_mem.v** | `tcm_mem` | Top-level da TCM (memória rápida sem cache) |
| **tcm_mem_ram.v** | `tcm_mem_ram` | RAM inferida para TCM |
| **tcm_mem_pmem.v** | `tcm_mem_pmem` | Interface de memória externa |
| **dport_axi.v** | `dport_axi` | Debug port AXI |
| **dport_mux.v** | `dport_mux` | Multiplexador de debug port |

---

### src/top/ - Top-level Wrappers

| Arquivo | Módulo | Descrição |
|---------|--------|-----------|
| **riscv_top.v** | `riscv_top` | Wrapper do core + icache + dcache + AXI4 interfaces |
| **riscv_tcm_top.v** | `riscv_tcm_top` | Wrapper do core + TCM (sem cache) + AXI4 Lite |

---

## ⚙️ synthesis/ - Síntese Lógica com Cadence Genus

Diretório central para síntese ASIC usando **Cadence Genus** @ GPDK045 45nm.

### synthesis/scripts/ - Scripts TCL de Síntese

| Arquivo | Descrição |
|---------|-----------|
| **run_first.tcl** | **Launcher principal** - executa `genus -f synthesis/scripts/riscv_core.tcl` com configurações de ambiente |
| **riscv_core.tcl** | **Script principal de síntese** - fluxo completo: read HDL → elaborate → generic → map → optimize → write netlist/SDF/reports |

#### synthesis/scripts/common/ - Scripts Compartilhados

| Arquivo | Descrição |
|---------|-----------|
| **path.tcl** | Define variáveis de diretórios (`SYNT_DIR`, `SRC_DIR`, `CORE_DIR`, `LIB_DIR`, `LEF_DIR`, `RPT_DIR`, `DEV_DIR`) |
| **tech.tcl** | Configuração de tecnologia GPDK045: bibliotecas (.lib), LEF, QRC, operating conditions (WORST=0.9V/125C, BEST=1.32V/0C), interconnect mode (PLE/wireload), dont_use cells (scan FFs, latches) |
| **sdf_width_wa.etf** | Workaround para warnings de width mismatch no SDF (Cadence-specific) |
| **READ_HDL_ALTERNATIVES.txt** | Documentação sobre diferentes métodos de leitura HDL (consolidado vs filelist) |

---

### synthesis/constraints/ - Timing Constraints

| Arquivo | Descrição |
|---------|-----------|
| **riscv_core.sdc** | **SDC (Synopsys Design Constraints)** - define: clock (`clk_i`, período variável por `FREQ_MHZ`), reset (`rst_i`, false path), I/O delays (300ps fixos), output load (0.045pF), max fanout (16), max transition (0.5ns), input slew (min/max rise/fall) |

---

### synthesis/work/ - Diretório de Trabalho do Genus

Diretório temporário criado durante execução do Genus. Contém:
- Databases intermediários (`.db`, `.gv`)
- Logs de execução
- Arquivos temporários

**Não versionado no Git** (listado em `.gitignore`).

---

### synthesis/reports/ - Relatórios de Síntese

Estrutura: `reports/<FREQ>_MHz/<CORNER>/`

Exemplo: `reports/190_MHz/WORST/`

| Arquivo | Descrição |
|---------|-----------|
| **riscv_core_timing.rpt** | **Análise de timing** - slack (positivo = MET), caminhos críticos (setup/hold), início/fim de cada path. **Mais importante para verificar sucesso da síntese!** |
| **riscv_core_area.rpt** | **Relatório de área** - área total (µm²), breakdown por tipo de célula (sequential/combinational/buffer), hierarquia de módulos |
| **riscv_core_gates.rpt** | **Contagem de células** - número total de gates, flip-flops, buffers, inverters, por tipo |
| **riscv_core_power.rpt** | **Consumo de potência** - dynamic power, leakage power, total power (mW), breakdown por módulo |
| **riscv_core_qor.rpt** | **QoR (Quality of Results)** - resumo: slack, área, power, instance count, utilização |
| **riscv_core_timing_lint.rpt** | **Timing lint** - verifica problemas estruturais: latches inferidos, combinational loops, missing constraints. **Deve ter ZERO problemas!** |

**Resultados de referência @ 190 MHz WORST:**
- Slack: +0.2 ps (TIMING MET)
- Cells: 26,894 (3,347 FFs, 23,547 comb)
- Área: 74,962 µm² (cell) / 109,116 µm² (total)
- Power: ~3,878 µW @ 190 MHz

---

### synthesis/deliverables/ - Netlist e SDF

Estrutura: `deliverables/<FREQ>_MHz/<CORNER>/`

Exemplo: `deliverables/190_MHz/WORST/`

| Arquivo | Descrição |
|---------|-----------|
| **riscv_core.v** | **Netlist sintetizado** - Verilog gate-level com células da biblioteca GPDK045 (NAND2X1, DFFRHQX1, etc), wires, instâncias. Usado em **simulação gate-level (GLS)** |
| **riscv_core.sdf** | **SDF (Standard Delay Format)** - delays de propagação reais de cada célula e net (rise/fall, min:typ:max). Anotado no netlist durante simulação GLS no **Xcelium** para verificar timing real |

---

## 🧪 tb/ - Testbenches

### tb/tb_core_icarus/ - Testbench Simplificado

Testbench minimalista para simulação RTL e gate-level do **core isolado** (sem cache).

| Arquivo | Descrição |
|---------|-----------|
| **tb_top.v** | **Testbench RTL** - instancia `riscv_core`, memória TCM, carrega binário (.bin) em memória, gera clock/reset, monitora execução |
| **tb_top_postsyn.v** | **Testbench GLS** - versão para simulação gate-level, instancia netlist sintetizado (`riscv_core.v`) + células da biblioteca, anota SDF |
| **tcm_mem.v** | Wrapper da memória TCM - conecta instrução e dados |
| **tcm_mem_ram.v** | RAM inferida - array de 32 bits, inicializada com `$readmemh` do arquivo `.bin` |
| **biriscv_trace_sim_gls.sv** | Monitor de trace para GLS (SystemVerilog) - imprime instruções executadas, PC, registradores |
| **makefile** | Targets para simulação com **Icarus Verilog** (alternativa open-source, não usado no projeto atual) |
| **gtksettings.sav** | Configuração salva do GTKWave (waveform viewer para Icarus) |

---

### tb/tb_tcm/ - Testbench com TCM

Testbench SystemC usando Verilator para `riscv_tcm_top` (core + TCM + AXI4 Lite).

| Arquivo | Descrição |
|---------|-----------|
| **main.cpp** | Main SystemC - instancia testbench, roda clock, carrega ELF |
| **testbench.h** | Header do testbench SystemC |
| **testbench_vbase.h** | Base class do testbench |
| **riscv_tcm_top_rtl.h/.cpp** | Wrapper Verilator para `riscv_tcm_top` |
| **elf_load.h/.cpp** | Função para carregar ELF em memória |
| **mem_api.h** | API de acesso à memória |
| **sc_reset_gen.h** | Gerador de reset em SystemC |
| **axi4_lite.h** | Definições AXI4 Lite |
| **axi4.h** | Definições AXI4 |
| **makefile** | Compila com Verilator + SystemC |
| **makefile.generate_verilated** | Gera C++ do Verilog com Verilator |
| **makefile.build_verilated** | Compila código Verilator |
| **makefile.build_sysc_tb** | Compila testbench SystemC |

---

### tb/tb_top/ - Testbench Completo

Testbench SystemC para `riscv_top` (core + icache + dcache + AXI4 full).

**Arquivos similares a `tb_tcm/`**, mas para `riscv_top`:

| Arquivo | Descrição |
|---------|-----------|
| **main.cpp** | Main SystemC |
| **riscv_top.h/.cpp** | Wrapper Verilator para `riscv_top` |
| **tb_axi4_mem.h/.cpp** | Modelo de memória AXI4 (behavioral) |
| **elf_load.h/.cpp** | Loader de ELF |
| **axi4_defines.h** | Macros AXI4 |
| **axi4.h** | Tipos AXI4 |
| Outros arquivos similares a `tb_tcm/` |

---

## 🔧 Ferramentas Utilizadas

### Síntese Lógica
- **Cadence Genus** - Síntese lógica RTL-to-gates
  - Versão: 21.19 (demonstrada melhor performance que 21.18)
  - Licenças necessárias: `Genus_Synthesis`, `Genus_Physical_Opt`

### Simulação
- **Cadence Xcelium** - Simulador RTL e gate-level (mixed-signal)
  - Comandos: `xrun` (compilação + execução), `xmsdfc` (compilação SDF)
  - Flags: `-v2001` (Verilog 2001), `-gui` (SimVision GUI), `-access +rwc` (acesso read/write/connectivity para debug)
  
- **Cadence SimVision** - Waveform viewer integrado ao Xcelium
  - Scripts TCL: `waves.tcl`, `monitor.tcl`, `debug_loop.tcl`
  - Interface gráfica para visualizar sinais, hierarquia, debug

### Compilação RISC-V
- **riscv-gnu-toolchain** - Compilador GCC para RISC-V
  - Target: `riscv32-unknown-elf` (RV32IM)
  - ABI: `ilp32` (32-bit integer, 32-bit pointers)
  - Comandos: `riscv32-unknown-elf-gcc`, `riscv32-unknown-elf-objdump`, `riscv32-unknown-elf-readelf`

### Tecnologia (PDK)
- **GPDK045** - Generic PDK 45nm da Cadence
  - Standard cells: `gsclib045_svt_v4.4`
  - IO cells: `giolib045_v3.3`
  - Corners: WORST (0.9V, 125°C), BEST (1.32V, 0°C)
  - QRC: Extração RC para análise de timing

---

## 🚀 Fluxos de Trabalho

### 1. Compilar Aplicação RISC-V (WSL Ubuntu)
```bash
cd riscv-app-gen
make SRC=bubblesort/bubblesort.c    # Gera .elf, .bin, .s
make info ELF=bubblesort/bubblesort.elf  # Mostra entry point
```

### 2. Transferir Arquivos para Servidor (PowerShell)
```powershell
.\scripts\sync_to_server.ps1
```

### 3. Executar Síntese (Servidor SSH)
```bash
ssh ufsm00290-figueiro202120243@192.168.139.58
cd /home/ufsm00290/ufsm00290-figueiro202120243/logic-synthesis-biriscv
make run-synth FREQ_MHZ=190 OP_CORNER=WORST
```

### 4. Analisar Resultados (Servidor)
```bash
cd synthesis/reports/190_MHz/WORST/
grep "slack" riscv_core_timing.rpt    # Verificar timing
cat riscv_core_qor.rpt                # QoR summary
```

### 5. Simulação RTL com SimVision (Servidor)
```bash
make sim-gui    # Abre Xcelium + SimVision com bubblesort.bin
```

### 6. Simulação Gate-Level com SimVision (Servidor)
```bash
make sim-pos-syn-gui FREQ_MHZ=190 OP_CORNER=WORST
```

---

## 📊 Métricas de Síntese

### Frequências Testadas (GPDK045 45nm, WORST corner)

| Freq (MHz) | Period (ps) | Slack (ps) | Cells | FF | Area (µm²) | Status |
|------------|-------------|------------|-------|-----|-----------|---------|
| 100 | 10000 | +++ | ~25k | ~2.8k | ~78k | ✅ Easy |
| 170 | 5880 | 0 | 26,708 | 2,870 | 82,238 | ✅ Baseline |
| 175 | 5710 | 0 | 26,933 | 3,380 | 79,462 | ✅ Pipeline |
| 185 | 5410 | +0.2 | 28,093 | 3,380 | 86,437 | ✅ Pipeline |
| 190 | 5260 | +0.2 | 26,894 | 3,347 | 74,962 | ✅ **Optimized** |

**Otimizações aplicadas @ 190 MHz:**
- Barrel shifter nativo Verilog (`<<`, `>>`, `>>>`) no ALU
- Registro de `mem_error_i` no LSU
- `EXTRA_DECODE_STAGE=1` no frontend
- Interconnect mode PLE (realista)

---

## 📝 Convenções de Nomenclatura

- **Sinais de entrada**: sufixo `_i` (ex: `clk_i`, `rst_i`)
- **Sinais de saída**: sufixo `_o` (ex: `mem_d_addr_o`)
- **Registradores**: sufixo `_q` ou `_r` (ex: `mem_addr_q`, `result_r`)
- **Wires combinacionais**: sufixo `_w` (ex: `resp_addr_w`)
- **Active-low**: sufixo `_n` (ex: `rst_n`)
- **Enables**: sufixo `_e` (ex: `mem_unaligned_e2_q`)

---

## 🔗 Referências

- **biRISC-V Original**: https://github.com/ultraembedded/biriscv
- **RISC-V ISA Spec**: `docs/riscv_isa_spec.pdf` (v2.1)
- **RISC-V Privileged Spec**: `docs/riscv_privileged_spec.pdf` (v1.11)
- **Cadence Genus User Guide**: `/home/tools/cadence/genus/doc/`
- **Cadence Xcelium User Guide**: `/home/tools/cadence/xcelium/doc/`
- **GPDK045 Documentation**: `${TECH_DIR}/docs/`

---

## ⚠️ Notas Importantes

1. **Síntese APENAS no servidor** - Genus não está disponível localmente (Windows/WSL)
2. **WSL APENAS para toolchain** - Compilar aplicações RISC-V, não para síntese/simulação
3. **Line endings CRÍTICOS** - Scripts editados no Windows precisam de `sed -i 's/\r$//'` no servidor
4. **Ordem HDL**: `biriscv_defs.v` SEMPRE primeiro (defines globais)
5. **I/O delays fixos**: 300ps (NÃO usar percentual do período em altas frequências)
6. **Simulação GUI**: Use `sim-gui` (RTL) ou `sim-pos-syn-gui` (GLS) com SimVision
7. **Timing MET**: Slack > 0 em `riscv_core_timing.rpt`
8. **Git workflow**: Branch `Douglas` para desenvolvimento, `master` para produção
