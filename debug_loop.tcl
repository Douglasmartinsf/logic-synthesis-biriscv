# debug_loop.tcl - Script de execução com timeout
# Executa a simulação por um tempo limitado e depois para

puts "=== Iniciando simulacao com timeout automatico ==="
puts "Tempo maximo: 5000us (5ms)"
puts ""

# Executa por 5000us (5ms) e para automaticamente
run 5000us

puts ""
puts "=== Simulacao parada apos timeout ==="
puts "Use 'run <tempo>' para continuar se necessario"
puts ""
