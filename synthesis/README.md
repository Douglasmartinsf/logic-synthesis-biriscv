# biRISC-V Logic Synthesis

Scripts e configurações para síntese lógica do processador biRISC-V usando Cadence Genus.

## Estrutura

```
synthesis/
├── scripts/
│   ├── common/
│   │   ├── path.tcl          # Definições de diretórios
│   │   ├── tech.tcl          # Configuração de tecnologia/bibliotecas
│   │   └── sdf_width_wa.etf  # Workaround para SDF
│   ├── riscv_core.tcl        # Script principal de síntese
│   └── run_first.tcl         # Launcher do Genus
├── constraints/
│   └── riscv_core.sdc        # Constraints de timing (SDC)
├── work/                     # Diretório de trabalho do Genus
├── reports/                  # Relatórios de síntese
│   └── <FREQ>_MHz/<CORNER>/
└── deliverables/             # Netlist e SDF gerados
    └── <FREQ>_MHz/<CORNER>/
```

## Uso Rápido

### 1. Preparar ambiente

```bash
# No servidor (via SSH)
cd /home/u32br/<seu_usuario>/arq3/logic-synthesis-biriscv

# Ajustar variáveis no Makefile:
# - USER (seu usuário)
# - PROJECT_DIR (caminho completo do projeto)
# - TECH_DIR (caminho do PDK)
```

### 2. Criar diretórios

```bash
make setup FREQ_MHZ=100 OP_CORNER=WORST
```

### 3. Executar síntese

```bash
make run-synth FREQ_MHZ=100 OP_CORNER=WORST
```

### 4. Analisar resultados

```bash
# Ver relatórios
cd synthesis/reports/100_MHz/WORST/

# Timing (mais importante)
cat riscv_core_timing.rpt | grep "slack"

# Área
cat riscv_core_area.rpt | grep "Total"

# QoR (Quality of Results)
cat riscv_core_qor.rpt
```

## Parâmetros Configuráveis

### Frequência (FREQ_MHZ)
- **50 MHz**: Conservador, fácil de atingir timing
- **100 MHz**: Recomendado para primeira síntese
- **200 MHz**: Requer otimizações
- **300+ MHz**: Desafiador, pode precisar pipelining adicional

### Corner (OP_CORNER)
- **WORST**: Worst-case (slow corner, low voltage, high temp)
- **BEST**: Best-case (fast corner, high voltage, low temp)

## Módulos Sintetizados

O script sintetiza 17 módulos Verilog (todos em `src/core/`):

**Essenciais:**
- `biriscv_defs.v` - Definições e macros
- `riscv_core.v` - Top module

**Pipeline stages:**
- `biriscv_fetch.v` - Instruction fetch
- `biriscv_decode.v` - Instruction decode
- `biriscv_issue.v` - Dual-issue logic
- `biriscv_exec.v` - Execution stage
- `biriscv_lsu.v` - Load/Store Unit

**Functional units:**
- `biriscv_alu.v` - Arithmetic Logic Unit
- `biriscv_multiplier.v` - Multiplicador
- `biriscv_divider.v` - Divisor
- `biriscv_npc.v` - Next PC logic
- `biriscv_frontend.v` - Frontend (fetch + branch predict)

**Support:**
- `biriscv_decoder.v` - Instruction decoder
- `biriscv_regfile.v` - Register file (32 x 32-bit)
- `biriscv_csr.v` - Control/Status Registers
- `biriscv_csr_regfile.v` - CSR register file
- `biriscv_mmu.v` - Memory Management Unit
- `biriscv_pipe_ctrl.v` - Pipeline control

**NÃO incluídos (não sintetizáveis):**
- `biriscv_trace_sim.v` - Debug trace (simulation only)
- `biriscv_xilinx_2r1w.v` - Xilinx-specific (FPGA only)

## Constraints (SDC)

### Clock
- **Nome**: `clk_i`
- **Período**: Calculado automaticamente por `FREQ_MHZ`
  - 100 MHz → 10.0 ns
  - 200 MHz → 5.0 ns
- **Uncertainty**: 0.05 ns (jitter)
- **Latency**: 0.10 ns (clock tree delay estimate)

### Reset
- **Nome**: `rst_i`
- **Tipo**: Asynchronous (`set_false_path`)

### I/O Timing
- **Input delay**: 30% do período de clock
- **Output delay**: 30% do período de clock
- **Output load**: 0.045 pF (típico para pad)

### Design Rules
- **Max fanout**: 16
- **Max transition**: 0.5 ns

## Relatórios Gerados

### timing.rpt
Análise de timing. **Slack positivo = OK**.
```
Path 1: clk_i (rise) -> reg1/D
  slack: 2.45 ns (MET)  ← Positivo = OK
```

### area.rpt
Área ocupada por tipo de célula.
```
Total cell area: 125000 µm²
Sequential: 35%
Combinational: 65%
```

### gates.rpt
Contagem de portas lógicas.
```
Total gates: 45000
Flip-flops: 8500
Latches: 0
```

### qor.rpt
Resumo de qualidade (QoR).
```
Worst slack: 1.23 ns
Area: 125000 µm²
Power: 45.2 mW @ 100 MHz
```

### power.rpt
Consumo de potência estimado.
```
Total power: 45.2 mW
Dynamic: 38.5 mW (85%)
Leakage: 6.7 mW (15%)
```

## Arquivos Gerados

### riscv_core.v (Netlist)
Netlist sintetizado com:
- Células da biblioteca (AND, OR, FF, etc.)
- Wire declarations
- Instâncias hierárquicas

### riscv_core.sdf (Standard Delay Format)
Delays de propagação para cada:
- Célula
- Net (interconexão)
- Setup/hold times

Usado em simulação gate-level (GLS) para verificar timing real.

## Troubleshooting

### Erro: "file not found"
```tcl
Error: Cannot find biriscv_alu.v
```
**Solução**: Verificar `init_hdl_search_path` em `scripts/riscv_core.tcl`

### Erro: "unresolved reference"
```tcl
Error: Cannot resolve module 'biriscv_multiplier'
```
**Solução**: Ordem errada em `read_hdl`. Ler dependências primeiro.

### Timing violation (slack negativo)
```
Worst slack: -0.85 ns (VIOLATED)
```
**Soluções**:
1. Reduzir `FREQ_MHZ` (ex: 100 → 80 MHz)
2. Aumentar `clk_uncertainty` no SDC
3. Ajustar `in_delay`/`out_delay` (reduzir % do período)
4. Otimizar RTL (reduzir critical path)

### Área muito grande
```
Total area: 450000 µm² (muito grande para tecnologia)
```
**Soluções**:
1. Verificar `report_area -detail` para módulos grandes
2. Reduzir configurações do core (parâmetros em `biriscv_defs.v`)
3. Desabilitar features opcionais (MMU, branch prediction)

### Licença Genus não disponível
```
Error: License checkout failed for Genus_Synthesis
```
**Solução**: Verificar com administrador do servidor. Aguardar licença disponível.

## Customização

### Alterar tecnologia (PDK)
Editar `Makefile`:
```makefile
TECH_DIR := /home/tools/design_kits/cadence/IBM180/
```

Editar `scripts/riscv_core.tcl`:
```tcl
set WORST_LIST {<nome_lib_slow>.lib}
set BEST_LIST {<nome_lib_fast>.lib}
set LEF_LIST {<tech>.lef <macro>.lef}
set QRC_LIST {<caminho_qrc>/qrcTechFile}
```

### Alterar constraints
Editar `constraints/riscv_core.sdc`:
```tcl
# Exemplo: Clock de 50 MHz em vez de variável
create_clock -name clk_i -period 20.0 [get_ports clk_i]
```

### Adicionar otimizações
Editar `scripts/riscv_core.tcl` antes de `syn_map`:
```tcl
# Exemplo: Forçar ungroup para melhor otimização
set_db auto_ungroup both

# Exemplo: Effort level máximo
set_db syn_map_effort high
```

## Referências

- **Genus User Guide**: `/home/tools/cadence/genus/doc/`
- **GPDK045 Documentation**: `${TECH_DIR}/docs/`
- **biRISC-V Original**: https://github.com/ultraembedded/biriscv
- **SDC Syntax**: IEEE 1481-2009 Standard
