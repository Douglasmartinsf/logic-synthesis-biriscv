puts "--- INICIANDO MONITORAMENTO DE PROGRESSO ---"

# Tenta rodar 50 passos de 100us (Total 5ms)
for {set i 1} {$i <= 50} {incr i} {
    # Roda 100us
    run 100 us
    
    # Imprime o tempo atual da simulação para confirmar que não travou
    puts "Simulacao viva! Tempo atual: [run -time]"
}

puts "--- SUCESSO! A simulação chegou ao fim do monitoramento. ---"
exit
