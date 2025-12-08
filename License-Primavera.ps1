# Sistema de Licenciamento PRIMAVERA
# Script principal para licenciar clientes
# Inclui GUI com Windows Forms, validacoes e agendamento automatico

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Configuracao

# Diretorios do sistema
$vaultDir = "C:\PrimaveraLicenseVault"
$masterDir = "$vaultDir\Master"
$databaseDir = "$vaultDir\Database"
$backupDir = "$vaultDir\Backups"
$logsDir = "$vaultDir\Logs"

# Arquivo de base de dados
$databaseFile = "$databaseDir\licenses.json"
$logFile = "$logsDir\licensing.log"

# Arquivos master de licenca
$masterFiles = @(
    @{ Name = "Primavera.hlf"; Path = "$masterDir\Primavera.hlf" },
    @{ Name = "PRILIC.lic"; Path = "$masterDir\PRILIC.lic" }
)

# Periodos de licenca disponiveis
$licensePeriods = @{
    "3m" = @{ Label = "3 meses"; Days = 90 }
    "6m" = @{ Label = "6 meses"; Days = 180 }
    "1a" = @{ Label = "1 ano"; Days = 365 }
    "2a" = @{ Label = "2 anos"; Days = 730 }
}

#endregion

#region Funcoes Helper

function Write-LicenseLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

function Initialize-LicenseSystem {
    # Criar diretorios se nao existirem
    @($vaultDir, $masterDir, $databaseDir, $backupDir, $logsDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-LicenseLog "Diretorio criado: $_"
        }
    }

    # Criar base de dados se nao existir
    if (-not (Test-Path $databaseFile)) {
        $emptyDb = @{
            version = "1.0"
            lastLicenseId = 0
            licenses = @()
        }
        $emptyDb | ConvertTo-Json -Depth 10 | Set-Content $databaseFile
        Write-LicenseLog "Base de dados criada: $databaseFile"
    }
}

function Get-LicenseDatabase {
    if (Test-Path $databaseFile) {
        return Get-Content $databaseFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-LicenseDatabase {
    param($Database)
    $Database | ConvertTo-Json -Depth 10 | Set-Content $databaseFile
}

function New-LicenseId {
    param($Database)
    $Database.lastLicenseId++
    return "LIC-{0:D4}" -f $Database.lastLicenseId
}

function Validate-NIF {
    param([string]$NIF)

    # Remover espacos e validar formato
    $NIF = $NIF -replace '\s', ''

    if ($NIF -notmatch '^\d{9}$') {
        return $false
    }

    # Algoritmo de validacao de NIF portugues
    $checkDigit = [int]$NIF[8].ToString()
    $sum = 0
    for ($i = 0; $i -lt 8; $i++) {
        $sum += [int]$NIF[$i].ToString() * (9 - $i)
    }

    $remainder = $sum % 11
    $expectedCheck = if ($remainder -in @(0, 1)) { 0 } else { 11 - $remainder }

    return $checkDigit -eq $expectedCheck
}

function Validate-Email {
    param([string]$Email)
    return $Email -match '^[\w\.-]+@[\w\.-]+\.\w{2,}$'
}

function Get-TargetPaths {
    # Retorna os caminhos possiveis onde os arquivos devem ser copiados
    $basePaths = @(
        "C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP",
        "C:\Program Files\PRIMAVERA\SG100\Config\LP"
    )

    return $basePaths
}

function Copy-LicenseFiles {
    param(
        [string]$LicenseId,
        [array]$TargetPaths
    )

    $copiedFiles = @()

    foreach ($master in $masterFiles) {
        if (-not (Test-Path $master.Path)) {
            Write-LicenseLog "ERRO: Arquivo master nao encontrado: $($master.Path)"
            throw "Arquivo master nao encontrado: $($master.Name)"
        }

        # Criar backup antes de copiar
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$backupDir\$timestamp"
        if (-not (Test-Path $backupPath)) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        }
        Copy-Item $master.Path -Destination "$backupPath\$($master.Name)" -Force

        # Copiar para todos os caminhos possiveis
        foreach ($targetBase in $TargetPaths) {
            $targetPath = Join-Path $targetBase $master.Name
            $targetDir = Split-Path $targetPath

            # Criar diretorio se nao existir
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                Write-LicenseLog "Diretorio criado: $targetDir"
            }

            try {
                Copy-Item $master.Path -Destination $targetPath -Force
                Write-LicenseLog "Arquivo copiado: $targetPath"

                # Calcular hash para verificacao de integridade
                $hash = (Get-FileHash -Path $targetPath -Algorithm SHA256).Hash

                $copiedFiles += @{
                    name = $master.Name
                    sourcePath = $master.Path
                    targetPath = $targetPath
                    hash = "SHA256:$hash"
                    timestamp = Get-Date -Format "o"
                }
            }
            catch {
                Write-LicenseLog "ERRO ao copiar $($master.Name) para $targetPath`: $($_.Exception.Message)"
            }
        }
    }

    return $copiedFiles
}

function Schedule-LicenseExpiry {
    param(
        [string]$LicenseId,
        [datetime]$ExpiryDate
    )

    $taskName = "PRIMAVERA_License_Expiry_$LicenseId"
    $scriptPath = Join-Path (Split-Path $PSCommandPath) "Delete-PrimaveraFiles.ps1"

    # Verificar se o script de remocao existe
    if (-not (Test-Path $scriptPath)) {
        Write-LicenseLog "AVISO: Script de remocao nao encontrado: $scriptPath"
        return $false
    }

    # Remover tarefa existente se houver
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Criar acao
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    # Criar trigger para data de expiracao
    $trigger = New-ScheduledTaskTrigger -Once -At $ExpiryDate

    # Criar principal
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Configuracoes
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Registrar tarefa
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Remocao automatica de licenca PRIMAVERA (ID: $LicenseId)" | Out-Null
        Write-LicenseLog "Tarefa agendada criada: $taskName para $($ExpiryDate.ToString('dd/MM/yyyy HH:mm'))"
        return $true
    }
    catch {
        Write-LicenseLog "ERRO ao criar tarefa agendada: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region GUI

function Show-LicensingForm {
    # Criar formulario
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Licenciamento PRIMAVERA"
    $form.Size = New-Object System.Drawing.Size(500, 520)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # Titulo
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "SISTEMA DE LICENCIAMENTO PRIMAVERA"
    $lblTitle.Location = New-Object System.Drawing.Point(10, 10)
    $lblTitle.Size = New-Object System.Drawing.Size(460, 25)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblTitle.TextAlign = "MiddleCenter"
    $form.Controls.Add($lblTitle)

    # Separador
    $separator1 = New-Object System.Windows.Forms.Label
    $separator1.BorderStyle = "Fixed3D"
    $separator1.Location = New-Object System.Drawing.Point(10, 40)
    $separator1.Size = New-Object System.Drawing.Size(460, 2)
    $form.Controls.Add($separator1)

    $yPos = 55

    # Nome da Empresa
    $lblCompany = New-Object System.Windows.Forms.Label
    $lblCompany.Text = "Nome da Empresa:"
    $lblCompany.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblCompany.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($lblCompany)

    $txtCompany = New-Object System.Windows.Forms.TextBox
    $txtCompany.Location = New-Object System.Drawing.Point(180, $yPos)
    $txtCompany.Size = New-Object System.Drawing.Size(280, 20)
    $form.Controls.Add($txtCompany)

    $yPos += 35

    # NIF
    $lblNIF = New-Object System.Windows.Forms.Label
    $lblNIF.Text = "NIF:"
    $lblNIF.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblNIF.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($lblNIF)

    $txtNIF = New-Object System.Windows.Forms.TextBox
    $txtNIF.Location = New-Object System.Drawing.Point(180, $yPos)
    $txtNIF.Size = New-Object System.Drawing.Size(280, 20)
    $txtNIF.MaxLength = 9
    $form.Controls.Add($txtNIF)

    $yPos += 35

    # Email
    $lblEmail = New-Object System.Windows.Forms.Label
    $lblEmail.Text = "Email:"
    $lblEmail.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblEmail.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($lblEmail)

    $txtEmail = New-Object System.Windows.Forms.TextBox
    $txtEmail.Location = New-Object System.Drawing.Point(180, $yPos)
    $txtEmail.Size = New-Object System.Drawing.Size(280, 20)
    $form.Controls.Add($txtEmail)

    $yPos += 35

    # Morada
    $lblAddress = New-Object System.Windows.Forms.Label
    $lblAddress.Text = "Morada:"
    $lblAddress.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblAddress.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($lblAddress)

    $txtAddress = New-Object System.Windows.Forms.TextBox
    $txtAddress.Location = New-Object System.Drawing.Point(180, $yPos)
    $txtAddress.Size = New-Object System.Drawing.Size(280, 60)
    $txtAddress.Multiline = $true
    $form.Controls.Add($txtAddress)

    $yPos += 80

    # Periodo de Licenca
    $lblPeriod = New-Object System.Windows.Forms.Label
    $lblPeriod.Text = "Periodo de Licenca:"
    $lblPeriod.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblPeriod.Size = New-Object System.Drawing.Size(150, 20)
    $lblPeriod.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($lblPeriod)

    $yPos += 25

    # Radio buttons para periodo
    $radioPeriods = @{}
    $firstRadio = $null

    foreach ($key in @("3m", "6m", "1a", "2a")) {
        $period = $licensePeriods[$key]
        $radio = New-Object System.Windows.Forms.RadioButton
        $radio.Text = $period.Label
        $radio.Location = New-Object System.Drawing.Point(40, $yPos)
        $radio.Size = New-Object System.Drawing.Size(150, 20)
        $radio.Tag = $key
        $form.Controls.Add($radio)
        $radioPeriods[$key] = $radio

        if ($null -eq $firstRadio) {
            $firstRadio = $radio
            $radio.Checked = $true
        }

        $yPos += 25
    }

    $yPos += 10

    # Botoes
    $btnLicense = New-Object System.Windows.Forms.Button
    $btnLicense.Text = "Licenciar"
    $btnLicense.Location = New-Object System.Drawing.Point(280, $yPos)
    $btnLicense.Size = New-Object System.Drawing.Size(90, 30)
    $btnLicense.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnLicense.ForeColor = [System.Drawing.Color]::White
    $btnLicense.FlatStyle = "Flat"
    $form.Controls.Add($btnLicense)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancelar"
    $btnCancel.Location = New-Object System.Drawing.Point(380, $yPos)
    $btnCancel.Size = New-Object System.Drawing.Size(90, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    # Evento do botao Licenciar
    $btnLicense.Add_Click({
        # Validar campos
        if ([string]::IsNullOrWhiteSpace($txtCompany.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Por favor, insira o nome da empresa.", "Validacao", "OK", "Warning")
            return
        }

        if (-not (Validate-NIF $txtNIF.Text)) {
            [System.Windows.Forms.MessageBox]::Show("NIF invalido. Por favor, insira um NIF portugues valido (9 digitos).", "Validacao", "OK", "Warning")
            return
        }

        if (-not (Validate-Email $txtEmail.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Email invalido. Por favor, insira um email valido.", "Validacao", "OK", "Warning")
            return
        }

        if ([string]::IsNullOrWhiteSpace($txtAddress.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Por favor, insira a morada.", "Validacao", "OK", "Warning")
            return
        }

        # Obter periodo selecionado
        $selectedPeriod = $null
        foreach ($radio in $radioPeriods.Values) {
            if ($radio.Checked) {
                $selectedPeriod = $radio.Tag
                break
            }
        }

        # Armazenar dados e fechar
        $script:licenseData = @{
            CompanyName = $txtCompany.Text.Trim()
            NIF = $txtNIF.Text.Trim()
            Email = $txtEmail.Text.Trim()
            Address = $txtAddress.Text.Trim()
            Period = $selectedPeriod
        }

        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })

    # Mostrar formulario
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $script:licenseData
    }

    return $null
}

#endregion

#region Main

# Inicializar sistema
Initialize-LicenseSystem

Write-LicenseLog "=========================================
Write-LicenseLog "Iniciando processo de licenciamento PRIMAVERA"

# Verificar se arquivos master existem
$missingFiles = @()
foreach ($master in $masterFiles) {
    if (-not (Test-Path $master.Path)) {
        $missingFiles += $master.Name
    }
}

if ($missingFiles.Count -gt 0) {
    Write-LicenseLog "ERRO: Arquivos master nao encontrados: $($missingFiles -join ', ')"
    [System.Windows.Forms.MessageBox]::Show(
        "Arquivos master de licenca nao encontrados:`n`n$($missingFiles -join "`n")`n`nPor favor, coloque os arquivos em: $masterDir",
        "Erro - Arquivos Ausentes",
        "OK",
        "Error"
    )
    exit 1
}

# Mostrar formulario de licenciamento
$licenseData = Show-LicensingForm

if ($null -eq $licenseData) {
    Write-LicenseLog "Licenciamento cancelado pelo usuario"
    exit 0
}

Write-LicenseLog "Dados do cliente coletados: $($licenseData.CompanyName) (NIF: $($licenseData.NIF))"

# Carregar base de dados
$db = Get-LicenseDatabase

# Gerar ID de licenca
$licenseId = New-LicenseId -Database $db

# Calcular datas
$startDate = Get-Date
$periodInfo = $licensePeriods[$licenseData.Period]
$expiryDate = $startDate.AddDays($periodInfo.Days)

Write-LicenseLog "ID de Licenca: $licenseId"
Write-LicenseLog "Periodo: $($periodInfo.Label) ($($periodInfo.Days) dias)"
Write-LicenseLog "Data de Expiracao: $($expiryDate.ToString('dd/MM/yyyy HH:mm'))"

# Obter caminhos de destino
$targetPaths = Get-TargetPaths

# Copiar arquivos de licenca
try {
    $copiedFiles = Copy-LicenseFiles -LicenseId $licenseId -TargetPaths $targetPaths
    Write-LicenseLog "Arquivos de licenca copiados com sucesso ($($copiedFiles.Count) arquivo(s))"
}
catch {
    Write-LicenseLog "ERRO ao copiar arquivos: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show(
        "Erro ao copiar arquivos de licenca:`n`n$($_.Exception.Message)",
        "Erro",
        "OK",
        "Error"
    )
    exit 1
}

# Agendar remocao automatica
$scheduled = Schedule-LicenseExpiry -LicenseId $licenseId -ExpiryDate $expiryDate

# Criar registro de licenca
$license = @{
    licenseId = $licenseId
    client = @{
        companyName = $licenseData.CompanyName
        nif = $licenseData.NIF
        email = $licenseData.Email
        address = $licenseData.Address
    }
    licensing = @{
        startDate = $startDate.ToString("o")
        period = $licenseData.Period
        periodLabel = $periodInfo.Label
        periodDays = $periodInfo.Days
        expiryDate = $expiryDate.ToString("o")
        autoRemove = $scheduled
    }
    files = $copiedFiles
    history = @(
        @{
            action = "LICENSED"
            date = (Get-Date).ToString("o")
            user = $env:USERNAME
            details = "Licenca criada. Periodo: $($periodInfo.Label)"
        }
    )
}

# Adicionar a base de dados
$db.licenses += $license
Save-LicenseDatabase -Database $db

Write-LicenseLog "Licenca registrada na base de dados"
Write-LicenseLog "========================================="

# Mostrar mensagem de sucesso
$message = @"
LICENCIAMENTO CONCLUIDO COM SUCESSO!

ID da Licenca: $licenseId
Cliente: $($licenseData.CompanyName)
NIF: $($licenseData.NIF)

Periodo: $($periodInfo.Label)
Data de Inicio: $($startDate.ToString('dd/MM/yyyy HH:mm'))
Data de Expiracao: $($expiryDate.ToString('dd/MM/yyyy HH:mm'))

Arquivos copiados: $($copiedFiles.Count)
Remocao automatica: $(if ($scheduled) { "Agendada" } else { "Nao agendada" })

Os arquivos de licenca foram instalados com sucesso.
"@

[System.Windows.Forms.MessageBox]::Show($message, "Sucesso", "OK", "Information")

Write-LicenseLog "Processo de licenciamento concluido com sucesso"

#endregion
