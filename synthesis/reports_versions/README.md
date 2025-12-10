# Reports de Síntese - Comparação de Versões

Este diretório contém reports de síntese de diferentes versões do processador biRISC-V para análise comparativa.

## Estrutura

```
reports_versions/
├── baseline/           # Versão baseline (ripple shifter, sem otimizações)
│   ├── 170_MHz/
│   ├── 175_MHz/
│   ├── 185_MHz/
│   └── 190_MHz/
│
├── barrel_shifter/     # Otimização: Barrel shifter na ALU
│   └── (a ser adicionado)
│
├── mem_error_reg/      # Otimização: mem_error registrado no LSU
│   └── (a ser adicionado)
│
└── final_optimized/    # Todas as otimizações combinadas
    └── (a ser adicionado)
```

## Versões Planejadas

### 1. **baseline** ✅
- Descrição: Configuração original (ripple shifter)
- Status: Copiado do servidor
- Path servidor: `/home/ufsm00290/ufsm00290-figueiro202120243/logic-synthesis-biriscv/synthesis/reports`
- Frequências: 170, 175, 185, 190 MHz

### 2. **barrel_shifter** (próximo)
- Descrição: ALU otimizada com operadores nativos (<<, >>, >>>)
- Mudanças: `biriscv_alu.v` - barrel shifter inferido
- Esperado: Redução de área, melhoria de timing na ALU

### 3. **mem_error_reg** (futuro)
- Descrição: Sinal mem_error_i registrado no LSU
- Mudanças: `biriscv_lsu.v` - mem_error_q registrado
- Esperado: Quebra de caminho crítico Frontend → LSU

### 4. **final_optimized** (futuro)
- Descrição: Todas as otimizações combinadas
- Mudanças: barrel_shifter + mem_error_reg + EXTRA_DECODE_STAGE
- Esperado: Máxima frequência, melhor área

## Como Adicionar Nova Versão

1. **Criar diretório para nova versão:**
   ```powershell
   mkdir synthesis\reports_versions\<nome_versao>
   ```

2. **Copiar reports do servidor:**
   ```powershell
   scp -r ufsm00290-figueiro202120243@192.168.139.58:/home/ufsm00290/.../synthesis/reports/* synthesis\reports_versions\<nome_versao>\
   ```

3. **Atualizar este README** com descrição da versão

## Análise Comparativa

Para comparar versões, verifique os seguintes reports:

- **`riscv_core_timing.rpt`**: Slack, caminho crítico, frequência máxima
- **`riscv_core_area.rpt`**: Área total, células, FFs
- **`riscv_core_qor.rpt`**: Quality of Results summary
- **`riscv_core_power.rpt`**: Consumo de potência

## Métricas de Referência (Baseline @ 190 MHz)

| Métrica | Valor |
|---------|-------|
| Frequência | 190 MHz |
| Slack | +0.2 ps |
| Cells | 26,894 |
| FFs | 3,347 |
| Area | 74,962 µm² |
| Power | ~3,880 µW |

---

**Última atualização:** 2 de dezembro de 2025
