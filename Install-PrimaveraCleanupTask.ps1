# Script de instalação da tarefa agendada
# Agenda a eliminação de arquivos PRIMAVERA para todo dia 01 de Janeiro
# Compatível com Windows 7, 8, 10 e 11

# Verificar se está executando como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERRO: Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "Clique com botão direito e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Instalador de Tarefa Agendada PRIMAVERA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Caminho do script principal
$scriptPath = Join-Path $PSScriptRoot "Delete-PrimaveraFiles.ps1"

# Verificar se o script existe
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERRO: Script Delete-PrimaveraFiles.ps1 não encontrado!" -ForegroundColor Red
    Write-Host "Certifique-se que ambos os scripts estão na mesma pasta." -ForegroundColor Yellow
    pause
    exit 1
}

# Nome da tarefa
$taskName = "PRIMAVERA_Annual_Cleanup"

# Verificar se tarefa já existe
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Tarefa agendada já existe. Removendo versão antiga..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Write-Host "Criando tarefa agendada..." -ForegroundColor Green

# Criar ação - executar o script PowerShell
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Criar trigger - todo dia 01 de Janeiro às 00:05
$trigger = New-ScheduledTaskTrigger -Daily -At "00:05" -DaysInterval 365

# Ajustar data de início para próximo 01 de Janeiro
$currentYear = (Get-Date).Year
$nextJan1 = Get-Date -Year $currentYear -Month 1 -Day 1 -Hour 0 -Minute 5 -Second 0

# Se já passou 01 de Janeiro deste ano, começar no próximo ano
if ((Get-Date) -gt $nextJan1) {
    $nextJan1 = $nextJan1.AddYears(1)
}

$trigger.StartBoundary = $nextJan1.ToString("yyyy-MM-dd'T'HH:mm:ss")

# Criar principal - executar como SYSTEM com privilégios mais altos
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Configurações da tarefa
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

# Registrar a tarefa
try {
    Register-ScheduledTask -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "Eliminação anual de arquivos de licença PRIMAVERA (todo dia 01 de Janeiro)" | Out-Null

    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "INSTALAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detalhes da tarefa:" -ForegroundColor Cyan
    Write-Host "  Nome: $taskName" -ForegroundColor White
    Write-Host "  Próxima execução: $($nextJan1.ToString('dd/MM/yyyy HH:mm'))" -ForegroundColor White
    Write-Host "  Frequência: Anual (todo dia 01 de Janeiro)" -ForegroundColor White
    Write-Host "  Arquivos a deletar:" -ForegroundColor White
    Write-Host "    - C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\Primavera.hlf" -ForegroundColor White
    Write-Host "    - C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\PRILIC.lic" -ForegroundColor White
    Write-Host ""
    Write-Host "  Se a eliminação falhar, será feita nova tentativa após 5 dias." -ForegroundColor Yellow
    Write-Host "  Logs salvos em: C:\ProgramData\PrimaveraCleanup\deletion_log.txt" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Para visualizar a tarefa, abra o 'Agendador de Tarefas' do Windows." -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ERRO ao criar tarefa agendada:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    pause
    exit 1
}

pause
