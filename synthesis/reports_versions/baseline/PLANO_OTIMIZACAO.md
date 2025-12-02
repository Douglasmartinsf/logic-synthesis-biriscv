# Plano de Otimização - Baseline 170 MHz → 180+ MHz

## Status Atual
- ✅ **Baseline confirmado funcional**: 170 MHz @ WORST, slack = 0 ps
- ✅ **Simulação validada**: Bubblesort ordenando corretamente
- ✅ **Caminho crítico identificado**: Frontend (44.6%) + ALU (28.4%)

---

## Fase 1: Quick Wins (Baixo Risco) ⭐⭐⭐

### 1.1 Post-Mapping Optimization (TCL)
**Status**: ✅ Implementado em `riscv_core.tcl`

**Mudanças**:
- `set_max_fanout 8` para reduzir carga em sinais críticos
- `set_max_transition 0.15` para forçar buffering
- Upsizing automático de gates fracos (drive < 4) no caminho crítico
- `syn_opt -incr` para re-otimização

**Ganho esperado**: +3-5% freq (175-178 MHz)  
**Risco**: Muito baixo  
**Teste**: `make run-synth FREQ_MHZ=175 OP_CORNER=WORST`

### 1.2 Testar Frequências Superiores (Grátis)
**Objetivo**: Verificar se Genus consegue otimizar mais sem mudanças RTL

**Comandos**:
```bash
# Servidor
make run-synth FREQ_MHZ=180 OP_CORNER=WORST
make run-synth FREQ_MHZ=185 OP_CORNER=WORST
```

**Critério de sucesso**: Slack ≥ 0 ps  
**Se falhar**: Confirma necessidade de mudanças RTL (Fase 2)

---

## Fase 2: Frontend Pipeline (Médio Risco) ⭐⭐

### 2.1 Habilitar EXTRA_DECODE_STAGE
**Status**: ⚠️ Atualmente = 0 (desabilitado)

**Arquivos para modificar**:
1. `src/core/riscv_core.v` linha 39
2. `src/core/biriscv_frontend.v` linha 34
3. `src/core/biriscv_decode.v` linha 32

**Mudança**:
```verilog
// ANTES
,parameter EXTRA_DECODE_STAGE = 0

// DEPOIS
,parameter EXTRA_DECODE_STAGE = 1
```

**Impacto**:
- ✅ Reduz caminho frontend: ~300-400 ps (-11-14% do path crítico)
- ✅ Ganho esperado: +5-7% freq → 179-182 MHz
- ⚠️ Latência fetch: +1 ciclo (aceitável)
- ⚠️ Área: +100-150 FFs (~3-5%)

**Validação**:
```bash
# Após modificar
make sim  # Verificar se bubblesort ainda funciona
make run-synth FREQ_MHZ=180 OP_CORNER=WORST
```

---

## Fase 3: ALU Pipeline (Alto Risco) ⭐

### 3.1 Adicionar Output Register no ALU
**Status**: ⚠️ Tentativa anterior falhou (quebrou simulação)

**Problema anterior**:
- ALU pipelined com clock adicionado
- Simulação não executava programa (array não ordenado)
- Possível causa: latency mismatch ou timing de controle

**Estratégia revisada**:
1. **NÃO adicionar clock ao módulo `biriscv_alu.v`**
2. **Usar pipeline existente no `biriscv_exec.v`**
3. Apenas otimizar lógica combinacional do ALU (barrel shifter)

### 3.2 Barrel Shifter Paralelo (Alternativa)
**Objetivo**: Reduzir delay do ALU (1627 ps → ~1200 ps)

**Mudança em `biriscv_alu.v`**:
```verilog
// Substituir ripple shifter por operadores nativos
`ALU_SHIFTL: result_r = alu_a_r << alu_b_r[4:0];
`ALU_SHIFTR: result_r = alu_a_r >> alu_b_r[4:0];
`ALU_SHIFTR_ARITH: result_r = $signed(alu_a_r) >>> alu_b_r[4:0];
```

**CRÍTICO**: **NÃO adicionar pipeline extra** (usar apenas lógica combinacional)

**Validação**:
```bash
# 1. Sintetizar primeiro
make run-synth FREQ_MHZ=180 OP_CORNER=WORST

# 2. Só se timing MET, rodar simulação
make sim  # Verificar bubblesort

# 3. Se sim falhar, reverter imediatamente
git checkout HEAD -- src/core/biriscv_alu.v
```

**Ganho esperado**: +5-8% freq (se funcionar)  
**Risco**: Alto (tentativa anterior falhou)

---

## Cronograma de Execução

### Hoje (2 dez 2025)
- [x] Análise de timing completa
- [x] Quick win implementado (TCL optimization)
- [ ] Testar 175 MHz com TCL optimization
- [ ] Testar 180/185 MHz sem mudanças RTL

### Próxima sessão
- [ ] Se 180 MHz falhar: Implementar EXTRA_DECODE_STAGE=1
- [ ] Validar com simulação
- [ ] Tentar 185 MHz

### Futuro (se necessário)
- [ ] Debugar por que ALU pipeline falhou
- [ ] Tentar barrel shifter **sem** pipeline extra
- [ ] Última opção: Aceitar 180-185 MHz como máximo

---

## Critérios de Sucesso

| Métrica | Baseline | Target | Stretch Goal |
|---------|----------|--------|--------------|
| **Frequência** | 170 MHz | 180 MHz | 185 MHz |
| **Ganho** | - | +5.9% | +8.8% |
| **Slack** | 0 ps | ≥ 50 ps | ≥ 100 ps |
| **Área** | 82k µm² | < 86k µm² | < 90k µm² |
| **Simulação** | ✅ Pass | ✅ Pass | ✅ Pass |

---

## Comandos Rápidos

```bash
# Servidor - Testar otimização TCL
cd /home/ufsm00290/ufsm00290-figueiro202120243/logic-synthesis-biriscv
make run-synth FREQ_MHZ=175 OP_CORNER=WORST

# Verificar timing
grep -A 2 "Slack:" synthesis/reports/175_MHz/WORST/riscv_core_timing.rpt | head -5

# Se timing MET, testar 180 MHz
make run-synth FREQ_MHZ=180 OP_CORNER=WORST

# Comparar com baseline
diff synthesis/reports/170_MHz/WORST/riscv_core_qor.rpt \
     synthesis/reports/180_MHz/WORST/riscv_core_qor.rpt
```

---

**Última atualização**: 2 dez 2025 13:15  
**Próximo passo**: Sincronizar para servidor e testar 175 MHz
