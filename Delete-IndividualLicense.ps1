# Script para deletar arquivos de licenca individual PRIMAVERA
# Executado automaticamente pela tarefa agendada ao expirar a licenca
# Sistema de retry automatico a cada 2 horas durante 7 dias

param(
    [Parameter(Mandatory=$false)]
    [string]$LicenseId
)

#region Configuracao

# Diretorios de log e estado
$vaultDir = "C:\PrimaveraLicenseVault"
$logDir = "$vaultDir\Logs"
$logFile = "$logDir\deletion_log.txt"
$stateDir = "$vaultDir\DeletionState"

# Configuracao de retry - a cada 2 horas
$retryIntervalHours = 2
$maxRetryPeriodDays = 7  # Periodo maximo de tentativas (7 dias)

# Arquivos de licenca a deletar
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

# Criar diretorios se nao existirem
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

# Funcao para escrever no log
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    Write-Host $logMessage
}

# Funcao para carregar estado de retry
function Get-RetryState {
    param([string]$LicenseId)

    $stateFile = Join-Path $stateDir "$LicenseId.json"

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
        [string]$LicenseId,
        [datetime]$FirstAttempt,
        [datetime]$LastAttempt,
        [int]$TotalAttempts,
        [string[]]$FailedFiles
    )

    $stateFile = Join-Path $stateDir "$LicenseId.json"

    $state = @{
        LicenseId = $LicenseId
        FirstAttempt = $FirstAttempt.ToString("o")
        LastAttempt = $LastAttempt.ToString("o")
        TotalAttempts = $TotalAttempts
        FailedFiles = $FailedFiles
    }

    $state | ConvertTo-Json | Set-Content $stateFile
}

# Funcao para limpar estado de retry
function Clear-RetryState {
    param([string]$LicenseId)

    $stateFile = Join-Path $stateDir "$LicenseId.json"

    if (Test-Path $stateFile) {
        Remove-Item $stateFile -Force
        Write-Log "Estado de retry limpo para licenca $LicenseId"
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

#endregion

#region Execucao Principal

Write-Log "========================================="
Write-Log "Iniciando processo de eliminacao de licenca PRIMAVERA"

# Obter LicenseId da tarefa agendada se nao foi fornecido
if ([string]::IsNullOrWhiteSpace($LicenseId)) {
    # Tentar extrair do nome da tarefa em execucao
    $taskName = $env:SCHEDULED_TASK_NAME
    if ($taskName -match 'PRIMAVERA_License_Expiry_(.+)') {
        $LicenseId = $Matches[1]
        Write-Log "License ID obtido da tarefa agendada: $LicenseId"
    }
    else {
        Write-Log "ERRO: License ID nao fornecido e nao pode ser determinado"
        exit 1
    }
}

Write-Log "Processando expiracao da licenca: $LicenseId"

# Carregar estado de retry
$retryState = Get-RetryState -LicenseId $LicenseId
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
                # Remover atributos readonly e hidden antes de deletar
                if (Test-Path $filePath) {
                    $item = Get-Item -LiteralPath $filePath -Force
                    if ($item.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                        $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                    }
                    if ($item.Attributes -band [System.IO.FileAttributes]::Hidden) {
                        $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden)
                    }
                }

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

# Verificar se ainda esta dentro do periodo de 7 dias
$daysSinceFirst = ($currentTime - $firstAttempt).TotalDays
$withinRetryPeriod = $daysSinceFirst -lt $maxRetryPeriodDays

# Nome da tarefa agendada para esta licenca
$mainTaskName = "PRIMAVERA_License_Expiry_$LicenseId"
$retryTaskName = "PRIMAVERA_License_Expiry_Retry_$LicenseId"

# Se houve falhas e ainda esta dentro do periodo de retry
if ($failedCount -gt 0 -and $withinRetryPeriod) {

    # Calcular proxima tentativa (daqui a 2 horas)
    $retryDate = $currentTime.AddHours($retryIntervalHours)

    Write-Log "ATENCAO: Houve $failedCount falha(s)."
    Write-Log "Agendando proxima tentativa para: $($retryDate.ToString('dd/MM/yyyy HH:mm:ss'))"
    Write-Log "Dias restantes no periodo de retry: $([math]::Ceiling($maxRetryPeriodDays - $daysSinceFirst))"

    # Salvar estado
    Set-RetryState -LicenseId $LicenseId -FirstAttempt $firstAttempt -LastAttempt $currentTime -TotalAttempts $totalAttempts -FailedFiles $failedFiles

    # Remover tarefa de retry existente se houver
    $existingRetryTask = Get-ScheduledTask -TaskName $retryTaskName -ErrorAction SilentlyContinue
    if ($existingRetryTask) {
        Unregister-ScheduledTask -TaskName $retryTaskName -Confirm:$false
    }

    # Criar nova tarefa de retry
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -LicenseId `"$LicenseId`""
    $trigger = New-ScheduledTaskTrigger -Once -At $retryDate
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $retryTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Retry automatico (tentativa $totalAttempts) para eliminacao de licenca PRIMAVERA $LicenseId" | Out-Null

    Write-Log "Proxima tentativa agendada: $($retryDate.ToString('dd/MM/yyyy HH:mm:ss'))"
    exit 1
}
# Se houve falhas mas esgotou o periodo de 7 dias
elseif ($failedCount -gt 0 -and -not $withinRetryPeriod) {
    Write-Log "========================================="
    Write-Log "ERRO CRITICO: Periodo de retry de $maxRetryPeriodDays dias esgotado!"
    Write-Log "Total de tentativas realizadas: $totalAttempts"
    Write-Log "Licenca: $LicenseId"
    Write-Log "Arquivos que nao puderam ser deletados:"
    foreach ($file in $failedFiles) {
        Write-Log "  - $file"
    }
    Write-Log "Acao necessaria: Verificar permissoes e processos em execucao"
    Write-Log "========================================="

    # Limpar estado e tarefa de retry
    Clear-RetryState -LicenseId $LicenseId
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
    Write-Log "Licenca $LicenseId expirada e removida"

    # Limpar estado e remover tarefa de retry
    Clear-RetryState -LicenseId $LicenseId

    $retryTask = Get-ScheduledTask -TaskName $retryTaskName -ErrorAction SilentlyContinue
    if ($retryTask) {
        Unregister-ScheduledTask -TaskName $retryTaskName -Confirm:$false
        Write-Log "Tarefa de retry removida (nao e mais necessaria)"
    }

    # Remover a tarefa principal de expiracao
    try {
        $mainTask = Get-ScheduledTask -TaskName $mainTaskName -ErrorAction SilentlyContinue
        if ($mainTask) {
            Unregister-ScheduledTask -TaskName $mainTaskName -Confirm:$false
            Write-Log "========================================="
            Write-Log "TAREFA DE EXPIRACAO REMOVIDA COM SUCESSO!"
            Write-Log "A tarefa '$mainTaskName' foi removida automaticamente."
            Write-Log "A licenca $LicenseId foi expirada e os arquivos eliminados."
            Write-Log "========================================="
        }
    }
    catch {
        Write-Log "AVISO: Nao foi possivel remover a tarefa de expiracao: $($_.Exception.Message)"
    }

    # Atualizar base de dados de licencas
    $databaseFile = "$vaultDir\Database\licenses.json"
    if (Test-Path $databaseFile) {
        try {
            $db = Get-Content $databaseFile -Raw | ConvertFrom-Json

            # Encontrar a licenca e atualizar historico
            $license = $db.licenses | Where-Object { $_.licenseId -eq $LicenseId }
            if ($license) {
                $license.history += @{
                    action = "EXPIRED"
                    date = (Get-Date).ToString("o")
                    user = "SYSTEM"
                    details = "Licenca expirada automaticamente. Arquivos removidos."
                }

                $db | ConvertTo-Json -Depth 10 | Set-Content $databaseFile
                Write-Log "Base de dados atualizada com sucesso"
            }
        }
        catch {
            Write-Log "AVISO: Nao foi possivel atualizar base de dados: $($_.Exception.Message)"
        }
    }

    exit 0
}

#endregion
