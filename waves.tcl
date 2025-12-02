# waves.tcl - Configuração automática de waveform
# Adiciona sinais essenciais do Core e Memória

# 1. Cria a janela de Waveform se não existir
simvision -submit {window new WaveWindow -name "Debug RISC-V"}

# 2. Define os sinais de interesse (ajustados para a hierarquia tb_top.u_dut)
set my_signals [list \
    tb_top.clk \
    tb_top.rst \
    tb_top.u_dut.mem_i_pc_o \
    tb_top.u_dut.mem_i_inst_i \
    tb_top.u_dut.mem_i_valid_i \
    tb_top.u_dut.mem_i_accept_i \
    tb_top.u_dut.mem_d_addr_o \
    tb_top.u_dut.mem_d_data_wr_o \
    tb_top.u_dut.mem_d_wr_o \
    tb_top.u_dut.mem_d_data_rd_i \
    tb_top.u_dut.mem_d_ack_i \
    tb_top.u_dut.mem_d_accept_i \
]

# 3. Envia os sinais para a janela
simvision -submit "waveform add -signals $my_signals"

# 4. Mensagem de confirmação no console
puts "--- Waveform configurada automaticamente via waves.tcl ---"
