# Script para deletar arquivos da PRIMAVERA
# Executa anualmente em 01 de Janeiro
# Sistema de retry progressivo: 5, 10, 15 dias
# Verificação de integridade e auto-reparo
# Busca automática em múltiplas localizações

#region Configuração

# Diretórios de log e estado
$logDir = "$env:ProgramData\PrimaveraCleanup"
$logFile = "$logDir\deletion_log.txt"
$stateFile = "$logDir\retry_state.json"

# Nomes das tarefas
$mainTaskName = "PRIMAVERA_Annual_Cleanup"
$retryTaskName = "PRIMAVERA_Cleanup_Retry"

# Configuração de retry progressivo
$retryIntervals = @(5, 10, 15)  # Dias entre tentativas
$maxRetries = 3

# Arquivos base a procurar (sem caminho completo)
$targetFiles = @(
    "Primavera.hlf",
    "PRILIC.lic"
)

# Caminhos possíveis para instalação do PRIMAVERA
$possibleBasePaths = @(
    "C:\Program Files (x86)\PRIMAVERA",
    "C:\Program Files\PRIMAVERA",
    "C:\PRIMAVERA",
    "${env:ProgramFiles(x86)}\PRIMAVERA",
    "$env:ProgramFiles\PRIMAVERA"
)

# Subdiretórios possíveis dentro da instalação
$possibleSubPaths = @(
    "SG100\Config\LP",
    "Config\LP",
    "LP",
    "SG100\Config",
    "Config"
)

#endregion

#region Funções Auxiliares

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

# Função para carregar estado de retry
function Get-RetryState {
    if (Test-Path $stateFile) {
        try {
            $state = Get-Content $stateFile -Raw | ConvertFrom-Json
            return $state
        }
        catch {
            Write-Log "AVISO: Não foi possível ler arquivo de estado. Criando novo."
            return $null
        }
    }
    return $null
}

# Função para salvar estado de retry
function Set-RetryState {
    param(
        [int]$AttemptNumber,
        [datetime]$LastAttempt,
        [string[]]$FailedFiles
    )

    $state = @{
        AttemptNumber = $AttemptNumber
        LastAttempt = $LastAttempt.ToString("o")
        FailedFiles = $FailedFiles
    }

    $state | ConvertTo-Json | Set-Content $stateFile
}

# Função para limpar estado de retry
function Clear-RetryState {
    if (Test-Path $stateFile) {
        Remove-Item $stateFile -Force
        Write-Log "Estado de retry limpo"
    }
}

# Função para procurar arquivo em múltiplas localizações
function Find-PrimaveraFile {
    param([string]$FileName)

    $foundPaths = @()

    foreach ($basePath in $possibleBasePaths) {
        if (Test-Path $basePath) {
            foreach ($subPath in $possibleSubPaths) {
                $fullPath = Join-Path $basePath $subPath
                $filePath = Join-Path $fullPath $FileName

                if (Test-Path $filePath) {
                    $foundPaths += $filePath
                    Write-Log "  Encontrado: $filePath"
                }
            }
        }
    }

    # Também procurar recursivamente no diretório raiz do PRIMAVERA
    foreach ($basePath in $possibleBasePaths) {
        if (Test-Path $basePath) {
            try {
                $foundFiles = Get-ChildItem -Path $basePath -Filter $FileName -Recurse -ErrorAction SilentlyContinue
                foreach ($file in $foundFiles) {
                    if ($file.FullName -notin $foundPaths) {
                        $foundPaths += $file.FullName
                        Write-Log "  Encontrado (busca recursiva): $($file.FullName)"
                    }
                }
            }
            catch {
                # Ignorar erros de permissão durante busca recursiva
            }
        }
    }

    return $foundPaths
}

# Função para verificar e reparar tarefa anual
function Repair-MainTask {
    Write-Log "Verificando integridade da tarefa anual '$mainTaskName'..."

    $task = Get-ScheduledTask -TaskName $mainTaskName -ErrorAction SilentlyContinue

    if (-not $task) {
        Write-Log "AVISO: Tarefa anual não encontrada. Tentando recriar..."

        # Procurar script de instalação
        $installScript = Join-Path (Split-Path $PSCommandPath) "Install-PrimaveraCleanupTask.ps1"

        if (Test-Path $installScript) {
            Write-Log "Script de instalação encontrado. Executando auto-reparo..."
            try {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript -AutoRepair
                Write-Log "Auto-reparo concluído com sucesso"
            }
            catch {
                Write-Log "ERRO: Falha no auto-reparo - $($_.Exception.Message)"
            }
        }
        else {
            Write-Log "ERRO: Script de instalação não encontrado em: $installScript"
            Write-Log "Execute manualmente: Install-PrimaveraCleanupTask.ps1"
        }
        return $false
    }

    # Verificar se a tarefa está habilitada
    if ($task.State -eq 'Disabled') {
        Write-Log "AVISO: Tarefa anual está desabilitada. Habilitando..."
        Enable-ScheduledTask -TaskName $mainTaskName | Out-Null
        Write-Log "Tarefa habilitada com sucesso"
    }

    Write-Log "Verificação de integridade concluída. Tarefa está OK."
    return $true
}

#endregion

#region Execução Principal

Write-Log "========================================="
Write-Log "Iniciando processo de eliminação de arquivos PRIMAVERA"

# Verificar integridade da tarefa anual
Repair-MainTask

# Carregar estado de retry
$retryState = Get-RetryState
$attemptNumber = if ($retryState) { $retryState.AttemptNumber } else { 1 }

Write-Log "Tentativa #$attemptNumber de $maxRetries"

# Estatísticas
$deletedCount = 0
$notFoundCount = 0
$failedCount = 0
$failedFiles = @()

# Processar cada arquivo
foreach ($fileName in $targetFiles) {
    Write-Log "Procurando arquivo: $fileName"

    # Buscar arquivo em todas as localizações possíveis
    $foundPaths = Find-PrimaveraFile -FileName $fileName

    if ($foundPaths.Count -eq 0) {
        Write-Log "  INFO: Arquivo não encontrado em nenhuma localização"
        $notFoundCount++
    }
    else {
        Write-Log "  Encontradas $($foundPaths.Count) ocorrência(s)"

        foreach ($filePath in $foundPaths) {
            try {
                Remove-Item -Path $filePath -Force -ErrorAction Stop
                Write-Log "  SUCESSO: Arquivo deletado - $filePath"
                $deletedCount++
            }
            catch {
                Write-Log "  ERRO: Falha ao deletar - $($_.Exception.Message)"
                $failedFiles += $filePath
                $failedCount++
            }
        }
    }
}

Write-Log "========================================="
Write-Log "Resumo: $deletedCount deletado(s), $notFoundCount não encontrado(s), $failedCount falha(s)"

#endregion

#region Gestão de Retry

# Se houve falhas e ainda há tentativas disponíveis
if ($failedCount -gt 0 -and $attemptNumber -le $maxRetries) {

    # Calcular intervalo de retry progressivo
    $retryDays = $retryIntervals[$attemptNumber - 1]
    $retryDate = (Get-Date).AddDays($retryDays)

    Write-Log "ATENÇÃO: Houve $failedCount falha(s)."
    Write-Log "Agendando tentativa #$($attemptNumber + 1) para daqui a $retryDays dias..."

    # Salvar estado
    Set-RetryState -AttemptNumber ($attemptNumber + 1) -LastAttempt (Get-Date) -FailedFiles $failedFiles

    # Remover tarefa de retry existente se houver
    $existingRetryTask = Get-ScheduledTask -TaskName $retryTaskName -ErrorAction SilentlyContinue
    if ($existingRetryTask) {
        Unregister-ScheduledTask -TaskName $retryTaskName -Confirm:$false
    }

    # Criar nova tarefa de retry
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At $retryDate
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $retryTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Retry automático #$attemptNumber para eliminação de arquivos PRIMAVERA" | Out-Null

    Write-Log "Retry agendado para: $($retryDate.ToString('dd/MM/yyyy HH:mm:ss'))"
    Write-Log "Tentativa: $attemptNumber de $maxRetries"
    exit 1
}
# Se houve falhas mas esgotaram-se as tentativas
elseif ($failedCount -gt 0 -and $attemptNumber -gt $maxRetries) {
    Write-Log "========================================="
    Write-Log "ERRO CRÍTICO: Todas as $maxRetries tentativas falharam!"
    Write-Log "Arquivos que não puderam ser deletados:"
    foreach ($file in $failedFiles) {
        Write-Log "  - $file"
    }
    Write-Log "Ação necessária: Verificar permissões e processos em execução"
    Write-Log "========================================="

    # Limpar estado e tarefa de retry
    Clear-RetryState
    $retryTask = Get-ScheduledTask -TaskName $retryTaskName -ErrorAction SilentlyContinue
    if ($retryTask) {
        Unregister-ScheduledTask -TaskName $retryTaskName -Confirm:$false
        Write-Log "Tarefa de retry removida (tentativas esgotadas)"
    }

    exit 2
}
# Sucesso total
else {
    Write-Log "Processo concluído com sucesso!"

    # Limpar estado e remover tarefa de retry
    Clear-RetryState

    $retryTask = Get-ScheduledTask -TaskName $retryTaskName -ErrorAction SilentlyContinue
    if ($retryTask) {
        Unregister-ScheduledTask -TaskName $retryTaskName -Confirm:$false
        Write-Log "Tarefa de retry removida (não é mais necessária)"
    }

    exit 0
}

#endregion
