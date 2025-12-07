# Script para deletar arquivos da PRIMAVERA
# Executa anualmente em 01 de Janeiro
# Se falhar, tenta novamente após 5 dias

# Configuração de arquivos a deletar
$filesToDelete = @(
    "C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\Primavera.hlf",
    "C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\PRILIC.lic"
)

# Diretório de log
$logDir = "$env:ProgramData\PrimaveraCleanup"
$logFile = "$logDir\deletion_log.txt"

# Criar diretório de log se não existir
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Função para escrever no log
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

# Iniciar log
Write-Log "========================================="
Write-Log "Iniciando processo de eliminação de arquivos PRIMAVERA"

$allDeleted = $true
$deletedCount = 0
$notFoundCount = 0
$failedCount = 0

foreach ($file in $filesToDelete) {
    Write-Log "Processando: $file"

    if (Test-Path $file) {
        try {
            Remove-Item -Path $file -Force -ErrorAction Stop
            Write-Log "  SUCESSO: Arquivo deletado"
            $deletedCount++
        }
        catch {
            Write-Log "  ERRO: Falha ao deletar - $($_.Exception.Message)"
            $allDeleted = $false
            $failedCount++
        }
    }
    else {
        Write-Log "  INFO: Arquivo não encontrado (já foi deletado ou não existe)"
        $notFoundCount++
    }
}

Write-Log "========================================="
Write-Log "Resumo: $deletedCount deletado(s), $notFoundCount não encontrado(s), $failedCount falha(s)"

# Se houve falhas, agendar retry para daqui a 5 dias
if (-not $allDeleted) {
    Write-Log "ATENÇÃO: Houve falhas. Agendando nova tentativa para daqui a 5 dias..."

    $retryDate = (Get-Date).AddDays(5)
    $taskName = "PRIMAVERA_Cleanup_Retry"

    # Verificar se já existe uma tarefa de retry
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Criar ação para executar este script novamente
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    # Criar trigger para daqui a 5 dias
    $trigger = New-ScheduledTaskTrigger -Once -At $retryDate

    # Criar principal (executar com privilégios mais altos)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Criar configurações
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Registrar tarefa
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Retry automático para eliminação de arquivos PRIMAVERA" | Out-Null

    Write-Log "Retry agendado para: $($retryDate.ToString('dd/MM/yyyy HH:mm:ss'))"
    exit 1
}
else {
    Write-Log "Processo concluído com sucesso!"

    # Remover tarefa de retry se existir
    $retryTask = Get-ScheduledTask -TaskName "PRIMAVERA_Cleanup_Retry" -ErrorAction SilentlyContinue
    if ($retryTask) {
        Unregister-ScheduledTask -TaskName "PRIMAVERA_Cleanup_Retry" -Confirm:$false
        Write-Log "Tarefa de retry removida (não é mais necessária)"
    }

    exit 0
}
