# Script de instalacao da tarefa agendada
# Agenda a eliminacao de arquivos PRIMAVERA para todo dia 01 de Janeiro
# Compativel com Windows 7, 8, 10 e 11
# Suporta modo de auto-reparo

param(
    [switch]$AutoRepair
)

# Verificar se esta executando como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERRO: Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "Clique com botao direito e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    if (-not $AutoRepair) { pause }
    exit 1
}

if (-not $AutoRepair) {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Instalador de Tarefa Agendada PRIMAVERA" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
}
else {
    Write-Host "[Auto-Reparo] Recriando tarefa agendada..." -ForegroundColor Yellow
}

# Caminho do script principal
$scriptPath = Join-Path $PSScriptRoot "Delete-PrimaveraFiles.ps1"

# Verificar se o script existe
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERRO: Script Delete-PrimaveraFiles.ps1 nao encontrado!" -ForegroundColor Red
    Write-Host "Certifique-se que ambos os scripts estao na mesma pasta." -ForegroundColor Yellow
    if (-not $AutoRepair) { pause }
    exit 1
}

# Nome da tarefa
$taskName = "PRIMAVERA_Annual_Cleanup"

# Verificar se tarefa ja existe
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    if (-not $AutoRepair) {
        Write-Host "Tarefa agendada ja existe. Removendo versao antiga..." -ForegroundColor Yellow
    }
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

if (-not $AutoRepair) {
    Write-Host "Criando tarefa agendada..." -ForegroundColor Green
}

# Criar acao - executar o script PowerShell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Criar trigger - todo dia 01 de Janeiro as 00:05
$trigger = New-ScheduledTaskTrigger -Daily -At "00:05" -DaysInterval 365

# Ajustar data de inicio para 01 de Janeiro de 2026 ou posterior
$currentYear = (Get-Date).Year
$nextJan1 = Get-Date -Year $currentYear -Month 1 -Day 1 -Hour 0 -Minute 5 -Second 0

# Garantir que comeca no minimo em 2026
if ($nextJan1.Year -lt 2026) {
    $nextJan1 = Get-Date -Year 2026 -Month 1 -Day 1 -Hour 0 -Minute 5 -Second 0
}
elseif ((Get-Date) -gt $nextJan1) {
    $nextJan1 = $nextJan1.AddYears(1)
}

$trigger.StartBoundary = $nextJan1.ToString("yyyy-MM-dd'T'HH:mm:ss")

# Criar principal - executar como SYSTEM com privilegios mais altos
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Configuracoes da tarefa
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

# Registrar a tarefa
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Eliminacao anual de arquivos de licenca PRIMAVERA (todo dia 01 de Janeiro)" | Out-Null

    if ($AutoRepair) {
        Write-Host "[Auto-Reparo] Tarefa recriada com sucesso!" -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "INSTALACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Detalhes da tarefa:" -ForegroundColor Cyan
        Write-Host "  Nome: $taskName" -ForegroundColor White
        Write-Host ("  Proxima execucao: " + $nextJan1.ToString('dd/MM/yyyy HH:mm')) -ForegroundColor White
        Write-Host "  Frequencia: Anual (todo dia 01 de Janeiro)" -ForegroundColor White
        Write-Host "  Arquivos a deletar:" -ForegroundColor White
        Write-Host "    - Primavera.hlf (procura em multiplas localizacoes)" -ForegroundColor White
        Write-Host "    - PRILIC.lic (procura em multiplas localizacoes)" -ForegroundColor White
        Write-Host ""
        Write-Host "  Sistema de Retry Progressivo:" -ForegroundColor Cyan
        Write-Host "    - Tentativa 1: Imediatamente" -ForegroundColor White
        Write-Host "    - Tentativa 2: Apos 5 dias (se falhar)" -ForegroundColor White
        Write-Host "    - Tentativa 3: Apos 10 dias (se falhar)" -ForegroundColor White
        Write-Host "    - Tentativa 4: Apos 15 dias (se falhar)" -ForegroundColor White
        Write-Host ""
        Write-Host "  Logs salvos em: C:\ProgramData\PrimaveraCleanup\deletion_log.txt" -ForegroundColor Cyan
        Write-Host "  Estado de retry: C:\ProgramData\PrimaveraCleanup\retry_state.json" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Funcionalidades avancadas:" -ForegroundColor Yellow
        Write-Host "    - Busca automatica em multiplas localizacoes" -ForegroundColor Green
        Write-Host "    - Retry progressivo com ate 3 tentativas" -ForegroundColor Green
        Write-Host "    - Verificacao de integridade e auto-reparo" -ForegroundColor Green
        Write-Host ""
        Write-Host "Para visualizar a tarefa, abra o 'Agendador de Tarefas' do Windows." -ForegroundColor Gray
        Write-Host ""
    }
}
catch {
    Write-Host ""
    Write-Host "ERRO ao criar tarefa agendada:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    if (-not $AutoRepair) { pause }
    exit 1
}

if (-not $AutoRepair) { pause }
