# Análise do Caminho Crítico - Baseline @ 170 MHz

## Resumo Executivo

**Data Path Total**: 5730 ps  
**Slack**: 0 ps (MET - timing ok, mas sem margem)  
**Frequência**: 170 MHz (período: 5880 ps)  
**Condição**: WORST corner (PVT_0P9V_125C - 0.9V, 125°C)

---

## Decomposição do Caminho Crítico

### **Startpoint → Endpoint**
- **Origem**: `u_frontend_u_decode_genblk1.u_fifo_rd_ptr_q_reg[0]/CK` (Frontend decode FIFO)
- **Destino**: `u_exec0_result_q_reg[31]/D` (Execution unit resultado)

### **Breakdown por Estágio** (Total: 5730 ps)

| Estágio | Delay (ps) | % Total | Descrição |
|---------|-----------|---------|-----------|
| **1. Frontend Decode Logic** | 100→2655 = **2555 ps** | **44.6%** | FIFO read pointer → decisões de decode |
| **2. Control & Operand Routing** | 2655→4031 = **1376 ps** | **24.0%** | Sinais de controle + roteamento operandos |
| **3. ALU Computation** | 4031→5658 = **1627 ps** | **28.4%** | Operação aritmética no ALU ⭐ |
| **4. Result Mux** | 5658→5830 = **172 ps** | **3.0%** | Multiplexação final do resultado |

---

## Análise Detalhada

### **1. Frontend Decode (2555 ps - 44.6%)**

**Caminho**: FIFO read pointer → Decoders → Control signals

**Componentes críticos**:
- `u_fifo_rd_ptr_q_reg[0]` → 8 fanouts (alta carga)
- Múltiplas inversões (CLKINVX12, CLKINVX8)
- Lógica XOR/NAND/NOR complexa (decode de instruções)
- **Pior gate**: `g323406` (AND2X4) → 12 fanouts, delay 243 ps

**Problema identificado**:
- Fanout alto (12 saídas) em `g323406` indica controle centralizado
- Múltiplas inversões sugerem polaridade incorreta de sinais
- Path muito longo antes de chegar ao ALU

**Oportunidade de melhoria**: ⭐⭐⭐
- Pipeline extra no **frontend decode** (EXTRA_DECODE_STAGE=1)
- Replicar sinais de controle com fanout alto
- Otimizar lógica de decode (simplificar XOR chains)

---

### **2. Control & Operand Routing (1376 ps - 24.0%)**

**Caminho**: Control signals → Operand selection → ALU inputs

**Componentes críticos**:
- `g316171` (AOI22X1) → transição de 252 ps (alta!)
- `g314467`, `g313147` (CLKAND2X2) → gates fracos, delays 214/142 ps
- `g312877` (CLKINVX12) → 15 fanouts (!)

**Problema identificado**:
- **15 fanouts** em `g312877` → sinal de controle broadcast
- Gates X1/X2 (drive fraco) em caminho crítico
- AOI22X1 com 252 ps de transição → carga alta

**Oportunidade de melhoria**: ⭐⭐
- Buffering de sinais de controle (reduzir fanout)
- Upsizing de gates fracos (X1→X4, X2→X4)
- Early evaluation de multiplexers

---

### **3. ALU Computation (1627 ps - 28.4%)** ⭐⭐⭐

**Caminho**: `u_exec0_u_alu` interno (linhas 67-78 do report)

**Breakdown interno do ALU**:
```
4031 ps: Entrada no ALU (g24315)
4137 ps: CLKINVX4 (+106 ps)
4209 ps: NAND2X4 (+72 ps)
4359 ps: OAI21X4 (+150 ps) ← delay alto
4503 ps: AOI21X4 (+144 ps) ← delay alto
4591 ps: NOR2X4 (+88 ps)
4686 ps: NOR2X4 (+95 ps)
4815 ps: OAI21X4 (+129 ps) ← delay alto
4930 ps: AOI2BB1X4 (+116 ps)
5041 ps: OAI21X4 (+111 ps)
5290 ps: XNOR2X4 (+249 ps) ⚠️ PIOR GATE NO ALU
5414 ps: INVX1 (+124 ps) ← drive fraco
5538 ps: AOI21X4 (+124 ps)
5658 ps: OAI21X4 (+120 ps)
```

**Problema identificado**:
- **XNOR2X4**: 249 ps delay (43% do delay do ALU!) ⚠️
- **INVX1** no meio do caminho crítico (deveria ser X4+)
- Cadeia longa de gates OAI/AOI (10 gates em série)

**Provável operação**: Shift ou comparação complexa
- XNOR indica comparação bit-a-bit
- Cadeia OAI/AOI sugere ripple carry ou barrel shifter
- Consistente com **ripple shifter** conhecido no baseline

**Oportunidade de melhoria**: ⭐⭐⭐
- **Pipeline no ALU** (quebrar em 2 estágios)
- **Barrel shifter paralelo** (substituir ripple shifter)
- **Upsizing**: INVX1 → INVX4
- **Otimizar XNOR**: usar estrutura mais rápida (MUX-based)

---

### **4. Result Mux (172 ps - 3.0%)**

**Caminho**: ALU output → Result register

**Componentes**:
- `g238609` (INVX3) → 79 ps
- `g237493` (OAI21X4) → 92 ps

**Problema**: Mínimo, já otimizado ✅

---

## **Propostas de Otimização Priorizadas**

### **✅ Opção 1: Pipeline no ALU** (Mais Segura)

**Descrição**: Adicionar registrador entre ALU e result_q

**Mudanças**:
```verilog
// biriscv_alu.v - adicionar output register
always @(posedge clk or posedge rst)
    if (rst) result_q <= 32'b0;
    else     result_q <= result_r; // registrar saída
```

**Impacto estimado**:
- ✅ **Quebra caminho de 1627 ps em 2 ciclos**
- ✅ **Frequência esperada**: 185-190 MHz (+11-12%)
- ⚠️ **Latência**: +1 ciclo de execução
- ⚠️ **Área**: +32 FFs = +2% área

**Trade-off**: Latência vs Frequência (aceitável)

---

### **⚠️ Opção 2: Barrel Shifter Paralelo** (Mais Arriscada)

**Descrição**: Substituir ripple shifter (5 estágios if-else) por barrel shifter

**Mudanças**:
```verilog
// Shift operations com operadores nativos
`ALU_SHIFTL: result_r = alu_a_r << alu_b_r[4:0];
`ALU_SHIFTR: result_r = alu_a_r >> alu_b_r[4:0];
`ALU_SHIFTR_ARITH: result_r = $signed(alu_a_r) >>> alu_b_r[4:0];
```

**Impacto estimado**:
- ✅ **Reduz caminho ALU**: ~400-500 ps (25-30%)
- ⚠️ **Área**: +10-15% (barrel shifter é maior)
- ⚠️ **Risco**: Tentativa anterior quebrou simulação

**Status**: Requer debugging da tentativa anterior

---

### **✅ Opção 3: Frontend Pipeline** (Complementar)

**Descrição**: Já implementado (`EXTRA_DECODE_STAGE=1`)

**Verificação**:
```verilog
// biriscv_frontend.v - linha 34
parameter EXTRA_DECODE_STAGE = 1; // ← confirmar se = 1
```

**Impacto estimado**:
- ✅ **Reduz caminho frontend**: ~300-400 ps
- ✅ **Frequência**: +5-7%
- ⚠️ **Latência fetch**: +1 ciclo

**Status**: Checar se já ativo na baseline

---

### **✅ Opção 4: Control Signal Optimization** (Quick Win)

**Descrição**: Buffering + upsizing de sinais de controle

**Mudanças TCL**:
```tcl
# riscv_core.tcl - após syn_map
set_max_fanout 8 [all_inputs]
set_max_transition 100ps [all_designs]

# Upsize gates fracos no caminho crítico
eco_size_cells [get_cells -of [get_pins -of [get_timing_paths -max_paths 1] -filter "drive_strength < 4"]] -higher_drive
```

**Impacto estimado**:
- ✅ **Reduz delays**: 100-200 ps
- ✅ **Frequência**: +3-5%
- ⚠️ **Área**: +2-3%

**Status**: Fácil de implementar, baixo risco

---

## **Recomendação Final**

### **Estratégia Incremental (Menor Risco)**

1. **Fase 1**: Verificar `EXTRA_DECODE_STAGE=1` + Control Optimization
   - **Frequência esperada**: 175-178 MHz (+3-5%)
   - **Risco**: Baixo
   - **Esforço**: 1 hora

2. **Fase 2**: Pipeline no ALU (output register)
   - **Frequência esperada**: 185-190 MHz (+11-12%)
   - **Risco**: Médio (requer validação de latência)
   - **Esforço**: 2-3 horas

3. **Fase 3** (Opcional): Barrel shifter paralelo
   - **Frequência esperada**: 195-200 MHz (+15-18%)
   - **Risco**: Alto (tentativa anterior falhou)
   - **Esforço**: 4-6 horas (debug + implementação)

### **Quick Win Imediato**

```bash
# Testar com constraints mais agressivos (forçar otimização)
make run-synth FREQ_MHZ=180 OP_CORNER=WORST
```

Se timing MET @ 180 MHz → ganho "grátis" de otimização Genus  
Se timing VIOLATED → confirma necessidade de mudanças RTL

---

## **Arquivos para Modificar**

| Arquivo | Mudança | Prioridade |
|---------|---------|------------|
| `synthesis/scripts/riscv_core.tcl` | Control optimization constraints | ⭐⭐⭐ Alta |
| `src/core/biriscv_frontend.v` | Verificar EXTRA_DECODE_STAGE | ⭐⭐⭐ Alta |
| `src/core/biriscv_alu.v` | Pipeline output register | ⭐⭐ Média |
| `src/core/biriscv_exec.v` | Ajustar conexões se ALU mudar | ⭐⭐ Média |
| `src/core/biriscv_alu.v` | Barrel shifter paralelo | ⭐ Baixa (arriscada) |

---

**Autor**: Análise automática via GitHub Copilot  
**Data**: 2 de dezembro de 2025  
**Baseline**: 170 MHz @ WORST (PVT_0P9V_125C)  
**Target**: 185-190 MHz (+11-12%)
