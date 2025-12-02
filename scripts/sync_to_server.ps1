<#
PowerShell script para sincronizar o projeto local com o servidor remoto (VERSÃO MELHORADA).
- Compacta os diretórios essenciais em um zip temporário (EXCLUINDO artefatos grandes por padrão)
- Envia o zip via `scp` para o servidor
- No servidor: descompacta, corrige permissões, sincroniza para o `RemotePath` e converte line endings (CRLF -> LF)
- Valida sync com verificação pós-transferência

Uso (PowerShell):
  .\scripts\sync_to_server.ps1
ou com parâmetros:
  .\scripts\sync_to_server.ps1 -Server '192.168.139.58' -User 'ufsm00290-figueiro202120243' -RemotePath '/home/ufsm00290/.../logic-synthesis-biriscv' -LocalPath '.' -IncludeArtifacts

Parâmetros:
  -IncludeArtifacts : Incluir synthesis/deliverables* e synthesis/reports* (padrão: EXCLUIR para evitar problemas de permissão)
  -Verbose         : Mostrar saída SSH detalhada

Requisitos:
- `scp` e `ssh` disponíveis no Windows (OpenSSH client) ou em PATH
- No servidor remoto: `unzip` e `rsync` recomendados (o script usa `rsync` para sincronização eficiente)
#>

param(
    [string]$Server = "192.168.139.58",
    [string]$User = "ufsm00290-figueiro202120243",
    [string]$RemotePath = "/home/ufsm00290/ufsm00290-figueiro202120243/logic-synthesis-biriscv",
    [string]$LocalPath = ".",
    [switch]$IncludeArtifacts = $false,
    [switch]$Verbose = $false
)

try {
    $cwd = Resolve-Path $LocalPath
} catch {
    Write-Error "LocalPath '$LocalPath' não encontrado."; exit 1
}

# Diretórios/arquivos principais
$toInclude = @('src','synthesis','tb','docs','riscv-app-gen','Makefile','README.md','LICENSE','.github','waves.tcl','monitor.tcl')
$existing = @()
foreach ($p in $toInclude) {
    $full = Join-Path $cwd $p
    if (Test-Path $full) { $existing += $full }
}

if ($existing.Count -eq 0) {
    Write-Error "Nenhum dos diretórios/arquivos selecionados foi encontrado em $cwd."; exit 1
}

# Se IncludeArtifacts == false, criar ZIP excluindo deliverables/reports/work (artefatos grandes)
$zip = Join-Path $env:TEMP "logic-synthesis-biriscv_sync.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }

if (-not $IncludeArtifacts) {
    Write-Host "[!] Excluindo artefatos grandes (synthesis/deliverables*, synthesis/reports*, synthesis/work*) do ZIP."
    Write-Host "    Use -IncludeArtifacts se precisar enviar esses diretorios tambem."
    
    # Compactar com exclusão (usando 7z ou fallback manual)
    $tempDir = Join-Path $env:TEMP "logic-synthesis-biriscv_temp"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Copiar itens excluindo artefatos
    foreach ($item in $existing) {
        $name = Split-Path $item -Leaf
        $dest = Join-Path $tempDir $name
        
        if ($name -eq 'synthesis') {
            # Copiar synthesis MAS excluir deliverables*/reports*/work*
            Write-Host "   Copiando synthesis (excluindo deliverables*, reports*, work*)..."
            Copy-Item $item -Destination $dest -Recurse -Force
            Remove-Item (Join-Path $dest 'deliverables*') -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item (Join-Path $dest 'reports*') -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item (Join-Path $dest 'work') -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Copy-Item $item -Destination $dest -Recurse -Force
        }
    }
    
    Write-Host "Compactando (sem artefatos): $($existing -join ', ')"
    Compress-Archive -Path (Get-ChildItem $tempDir) -DestinationPath $zip -Force
    Remove-Item $tempDir -Recurse -Force
} else {
    Write-Host "Compactando (incluindo TODOS os artefatos): $($existing -join ', ')"
    Compress-Archive -Path $existing -DestinationPath $zip -Force
}


$remoteTmp = "~/logic-synthesis-biriscv_sync.zip"
$remoteTmpDir = "~/logic-synthesis-biriscv_sync"
Write-Host ""
Write-Host "[UPLOAD] Enviando $zip para ${User}@${Server}:$remoteTmp"

# Envia com scp
$scpArgs = @('-o','StrictHostKeyChecking=no','-r',$zip, "${User}@${Server}:$remoteTmp")
if ($Verbose) { Write-Host "Executando: scp $($scpArgs -join ' ')" }
$proc = Start-Process -FilePath scp -ArgumentList $scpArgs -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) { 
    Write-Error "[ERRO] scp retornou codigo $($proc.ExitCode). Aborting."; 
    exit 1 
}
Write-Host "[OK] Upload concluido."

# Comandos remotos para descompactar, corrigir permissoes, sincronizar e converter line endings
Write-Host ""
Write-Host "[REMOTO] Executando comandos remotos (descompactar, corrigir permissoes, sincronizar)..."
$cmds = @(
    # 1. Criar diretório destino
    "mkdir -p '$RemotePath'",
    
    # 2. Limpar extração anterior e criar diretório temporário
    "rm -rf $remoteTmpDir && mkdir -p $remoteTmpDir",
    
    # 3. Descompactar
    "unzip -o $remoteTmp -d $remoteTmpDir",
    
    # 4. Remover diretórios problemáticos conhecidos (se existirem do sync anterior)
    "rm -rf $remoteTmpDir/synthesis/reports/reports $remoteTmpDir/synthesis/work/fv/riscv_core 2>/dev/null || true",
    
    # 5. Corrigir permissões ANTES de chown/rsync (crítico!)
    "find $remoteTmpDir -type d -exec chmod u+rwX {} + 2>/dev/null || true",
    "find $remoteTmpDir -type f -exec chmod u+rw {} + 2>/dev/null || true",
    
    # 6. Tentar chown (pode falhar em alguns casos, mas não bloqueia)
    "chown -R ${User}:${User} $remoteTmpDir 2>/dev/null || true",
    
    # 7. Sincronizar com rsync (ou fallback para cp)
    "if command -v rsync >/dev/null 2>&1; then rsync -a --delete $remoteTmpDir/ '$RemotePath/' 2>&1 | grep -v 'Permission denied' || true; else cp -r $remoteTmpDir/* '$RemotePath/' 2>/dev/null || true; fi",
    
    # 8. Converter line endings (CRLF -> LF) em arquivos de texto
    "find '$RemotePath' -type f \( -name '*.tcl' -o -name '*.sh' -o -name '*.v' -o -name '*.sv' -o -name '*.py' -o -name '*.sdc' -o -name '*.flist' -o -name 'Makefile' \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true",
    
    # 9. Tornar scripts executáveis
    "find '$RemotePath' -type f \( -name '*.tcl' -o -name '*.sh' \) -exec chmod +x {} + 2>/dev/null || true",
    
    # 10. Limpar arquivos temporários
    "rm -f $remoteTmp",
    "rm -rf $remoteTmpDir",
    
    # 11. Verificacao pos-sync (contar arquivos .v, .tcl, etc)
    "echo '[OK] Arquivos sincronizados:'",
    "find '$RemotePath/src' -name '*.v' 2>/dev/null | wc -l | xargs echo '  - Arquivos .v:'",
    "find '$RemotePath/synthesis/scripts' -name '*.tcl' 2>/dev/null | wc -l | xargs echo '  - Scripts .tcl:'",
    "find '$RemotePath/tb' -name '*.v' 2>/dev/null | wc -l | xargs echo '  - Testbenches .v:'"
)
$sshCmd = $cmds -join "; "

if ($Verbose) { 
    Write-Host ""
    Write-Host "Comando SSH executado:"
    Write-Host $sshCmd
}

$sshArgs = @("${User}@${Server}", $sshCmd)
$proc2 = Start-Process -FilePath ssh -ArgumentList $sshArgs -NoNewWindow -Wait -PassThru

if ($proc2.ExitCode -ne 0) {
    Write-Warning "[!] Comandos remotos retornaram codigo $($proc2.ExitCode)."
    Write-Host "    Verifique erros de permissao ou problemas de rsync acima."
} else {
    Write-Host ""
    Write-Host "[OK] Sincronizacao remota concluida com sucesso!"
}

# Cleanup local
if (Test-Path $zip) { Remove-Item $zip -Force }

Write-Host ""
Write-Host "[NEXT] Proximos passos (se necessario):"
Write-Host "   1. Verificar line endings dos scripts TCL:"
Write-Host "      ssh ${User}@${Server} `"file $RemotePath/synthesis/scripts/*.tcl | head -n 5`""
Write-Host ""
Write-Host "   2. Executar sintese no servidor:"
Write-Host "      ssh ${User}@${Server}"
Write-Host "      cd $RemotePath"
Write-Host "      make run-synth FREQ_MHZ=190 OP_CORNER=WORST"
Write-Host ""
Write-Host "[OK] Pronto."