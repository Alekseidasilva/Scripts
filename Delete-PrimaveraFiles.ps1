# Script para deletar arquivos da PRIMAVERA
# Executa anualmente em 01 de Janeiro as 10:00
# Sistema de retry a cada 2 horas durante 15 dias
# Desativa tarefa automaticamente apos sucesso
# Verificacao de integridade e auto-reparo
# Busca automatica em multiplas localizacoes

#region Configuracao

# Diretorios de log e estado
$logDir = "$env:ProgramData\PrimaveraCleanup"
$logFile = "$logDir\deletion_log.txt"
$stateFile = "$logDir\retry_state.json"

# Nomes das tarefas
$mainTaskName = "PRIMAVERA_Annual_Cleanup"
$retryTaskName = "PRIMAVERA_Cleanup_Retry"

# Configuracao de retry - a cada 2 horas
$retryIntervalHours = 2
$maxRetryPeriodDays = 15  # Periodo maximo de tentativas (15 dias)

# Arquivos base a procurar (sem caminho completo)
$targetFiles = @(
    "Primavera.hlf",
    "PRILIC.lic"
)

# Caminhos possiveis para instalacao do PRIMAVERA
$possibleBasePaths = @(
    "C:\Program Files (x86)\PRIMAVERA",
    "C:\Program Files\PRIMAVERA",
    "C:\PRIMAVERA",
    "${env:ProgramFiles(x86)}\PRIMAVERA",
    "$env:ProgramFiles\PRIMAVERA"
)

# Subdiretorios possiveis dentro da instalacao
$possibleSubPaths = @(
    "SG100\Config\LP",
    "Config\LP",
    "LP",
    "SG100\Config",
    "Config"
)

#endregion

#region Funcoes Auxiliares

# Criar diretorio de log se nao existir
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Funcao para escrever no log
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

# Funcao para carregar estado de retry
function Get-RetryState {
    if (Test-Path $stateFile) {
        try {
            $state = Get-Content $stateFile -Raw | ConvertFrom-Json
            return $state
        }
        catch {
            Write-Log "AVISO: Nao foi possivel ler arquivo de estado. Criando novo."
            return $null
        }
    }
    return $null
}

# Funcao para salvar estado de retry
function Set-RetryState {
    param(
        [datetime]$FirstAttempt,
        [datetime]$LastAttempt,
        [int]$TotalAttempts,
        [string[]]$FailedFiles
    )

    $state = @{
        FirstAttempt = $FirstAttempt.ToString("o")
        LastAttempt = $LastAttempt.ToString("o")
        TotalAttempts = $TotalAttempts
        FailedFiles = $FailedFiles
    }

    $state | ConvertTo-Json | Set-Content $stateFile
}

# Funcao para limpar estado de retry
function Clear-RetryState {
    if (Test-Path $stateFile) {
        Remove-Item $stateFile -Force
        Write-Log "Estado de retry limpo"
    }
}

# Funcao para procurar arquivo em multiplas localizacoes
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

    # Tambem procurar recursivamente no diretorio raiz do PRIMAVERA
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
                # Ignorar erros de permissao durante busca recursiva
            }
        }
    }

    return $foundPaths
}

# Funcao para verificar e reparar tarefa anual
function Repair-MainTask {
    Write-Log "Verificando integridade da tarefa anual '$mainTaskName'..."

    $task = Get-ScheduledTask -TaskName $mainTaskName -ErrorAction SilentlyContinue

    if (-not $task) {
        Write-Log "AVISO: Tarefa anual nao encontrada. Tentando recriar..."

        # Procurar script de instalacao
        $installScript = Join-Path (Split-Path $PSCommandPath) "Install-PrimaveraCleanupTask.ps1"

        if (Test-Path $installScript) {
            Write-Log "Script de instalacao encontrado. Executando auto-reparo..."
            try {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript -AutoRepair
                Write-Log "Auto-reparo concluido com sucesso"
            }
            catch {
                Write-Log "ERRO: Falha no auto-reparo - $($_.Exception.Message)"
            }
        }
        else {
            Write-Log "ERRO: Script de instalacao nao encontrado em: $installScript"
            Write-Log "Execute manualmente: Install-PrimaveraCleanupTask.ps1"
        }
        return $false
    }

    # Verificar se a tarefa esta habilitada
    if ($task.State -eq 'Disabled') {
        Write-Log "AVISO: Tarefa anual esta desabilitada. Habilitando..."
        Enable-ScheduledTask -TaskName $mainTaskName | Out-Null
        Write-Log "Tarefa habilitada com sucesso"
    }

    Write-Log "Verificacao de integridade concluida. Tarefa esta OK."
    return $true
}

#endregion

#region Execucao Principal

Write-Log "========================================="
Write-Log "Iniciando processo de eliminacao de arquivos PRIMAVERA"

# Verificar integridade da tarefa anual
Repair-MainTask

# Carregar estado de retry
$retryState = Get-RetryState
$currentTime = Get-Date

if ($retryState) {
    $firstAttempt = [datetime]::Parse($retryState.FirstAttempt)
    $totalAttempts = $retryState.TotalAttempts + 1

    $daysSinceFirst = ($currentTime - $firstAttempt).TotalDays
    Write-Log "Tentativa #$totalAttempts (dia $([math]::Floor($daysSinceFirst) + 1) de $maxRetryPeriodDays)"
}
else {
    $firstAttempt = $currentTime
    $totalAttempts = 1
    Write-Log "Tentativa #$totalAttempts (primeira execucao)"
}

# Estatisticas
$deletedCount = 0
$notFoundCount = 0
$failedCount = 0
$failedFiles = @()

# Processar cada arquivo
foreach ($fileName in $targetFiles) {
    Write-Log "Procurando arquivo: $fileName"

    # Buscar arquivo em todas as localizacoes possiveis
    $foundPaths = Find-PrimaveraFile -FileName $fileName

    if ($foundPaths.Count -eq 0) {
        Write-Log "  INFO: Arquivo nao encontrado em nenhuma localizacao"
        $notFoundCount++
    }
    else {
        Write-Log "  Encontradas $($foundPaths.Count) ocorrencia(s)"

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
Write-Log "Resumo: $deletedCount deletado(s), $notFoundCount nao encontrado(s), $failedCount falha(s)"

#endregion

#region Gestao de Retry

# Verificar se ainda esta dentro do periodo de 15 dias
$daysSinceFirst = ($currentTime - $firstAttempt).TotalDays
$withinRetryPeriod = $daysSinceFirst -lt $maxRetryPeriodDays

# Se houve falhas e ainda esta dentro do periodo de retry
if ($failedCount -gt 0 -and $withinRetryPeriod) {

    # Calcular proxima tentativa (daqui a 2 horas)
    $retryDate = $currentTime.AddHours($retryIntervalHours)

    Write-Log "ATENCAO: Houve $failedCount falha(s)."
    Write-Log "Agendando proxima tentativa para: $($retryDate.ToString('dd/MM/yyyy HH:mm:ss'))"
    Write-Log "Dias restantes no periodo de retry: $([math]::Ceiling($maxRetryPeriodDays - $daysSinceFirst))"

    # Salvar estado
    Set-RetryState -FirstAttempt $firstAttempt -LastAttempt $currentTime -TotalAttempts $totalAttempts -FailedFiles $failedFiles

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

    Register-ScheduledTask -TaskName $retryTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Retry automatico (tentativa $totalAttempts) para eliminacao de arquivos PRIMAVERA" | Out-Null

    Write-Log "Proxima tentativa: $($retryDate.ToString('dd/MM/yyyy HH:mm:ss'))"
    exit 1
}
# Se houve falhas mas esgotou o periodo de 15 dias
elseif ($failedCount -gt 0 -and -not $withinRetryPeriod) {
    Write-Log "========================================="
    Write-Log "ERRO CRITICO: Periodo de retry de $maxRetryPeriodDays dias esgotado!"
    Write-Log "Total de tentativas realizadas: $totalAttempts"
    Write-Log "Arquivos que nao puderam ser deletados:"
    foreach ($file in $failedFiles) {
        Write-Log "  - $file"
    }
    Write-Log "Acao necessaria: Verificar permissoes e processos em execucao"
    Write-Log "========================================="

    # Limpar estado e tarefa de retry
    Clear-RetryState
    $retryTask = Get-ScheduledTask -TaskName $retryTaskName -ErrorAction SilentlyContinue
    if ($retryTask) {
        Unregister-ScheduledTask -TaskName $retryTaskName -Confirm:$false
        Write-Log "Tarefa de retry removida (periodo esgotado)"
    }

    exit 2
}
# Sucesso total - arquivos deletados ou nao encontrados
else {
    Write-Log "Processo concluido com sucesso!"
    Write-Log "Total de tentativas realizadas: $totalAttempts"

    # Limpar estado e remover tarefa de retry
    Clear-RetryState

    $retryTask = Get-ScheduledTask -TaskName $retryTaskName -ErrorAction SilentlyContinue
    if ($retryTask) {
        Unregister-ScheduledTask -TaskName $retryTaskName -Confirm:$false
        Write-Log "Tarefa de retry removida (nao e mais necessaria)"
    }

    # DESATIVAR a tarefa anual apos sucesso
    try {
        Disable-ScheduledTask -TaskName $mainTaskName -ErrorAction Stop | Out-Null
        Write-Log "========================================="
        Write-Log "TAREFA ANUAL DESATIVADA COM SUCESSO!"
        Write-Log "A tarefa '$mainTaskName' foi desativada automaticamente."
        Write-Log "Os arquivos foram eliminados e nao serao mais processados."
        Write-Log "========================================="
    }
    catch {
        Write-Log "AVISO: Nao foi possivel desativar a tarefa anual: $($_.Exception.Message)"
    }

    exit 0
}

#endregion
