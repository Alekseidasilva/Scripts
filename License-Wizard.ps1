# Wizard de Licenciamento PRIMAVERA
# Interface grafica com multiplas etapas (wizard)
# Sistema completo com agendamento automatico de exclusao

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Configuracao

# Diretorios do sistema
$scriptRoot = Split-Path -Parent $PSCommandPath
$vaultDir = "C:\PrimaveraLicenseVault"
$masterDir = $scriptRoot
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
    "3m" = @{ Label = "3 meses"; Days = 90; Description = "Licenca valida por 3 meses (90 dias)" }
    "6m" = @{ Label = "6 meses"; Days = 180; Description = "Licenca valida por 6 meses (180 dias)" }
    "1a" = @{ Label = "1 ano"; Days = 365; Description = "Licenca valida por 1 ano (365 dias)" }
    "2a" = @{ Label = "2 anos"; Days = 730; Description = "Licenca valida por 2 anos (730 dias)" }
}

# Cores do tema
$ColorPrimary = [System.Drawing.Color]::FromArgb(0, 122, 204)
$ColorSecondary = [System.Drawing.Color]::FromArgb(240, 240, 240)
$ColorSuccess = [System.Drawing.Color]::FromArgb(76, 175, 80)
$ColorWarning = [System.Drawing.Color]::FromArgb(255, 152, 0)
$ColorError = [System.Drawing.Color]::FromArgb(244, 67, 54)

#endregion

#region Funcoes Helper

function Write-LicenseLog {
    param([string]$Message)
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    if (-not (Test-Path $logFile)) {
        New-Item -ItemType File -Path $logFile -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

function Initialize-LicenseSystem {
    # Criar diretorios se nao existirem
    @($vaultDir, $databaseDir, $backupDir, $logsDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-LicenseLog "Diretorio criado: $_"
        }
    }

    # Proteger todos os arquivos do pacote, exceto o iniciador principal
    Protect-PackageFiles -PackageRoot $scriptRoot -MainEntry "LICENCIAR.bat"

    # Validar arquivos master diretamente do pacote
    foreach ($master in $masterFiles) {
        if (-not (Test-Path -LiteralPath $master.Path)) {
            $missingMessage = "ERRO: Arquivo master ausente ou inacessivel no pacote: $($master.Name). Confirme que ele foi distribuido junto ao LICENCIAR.bat."
            Write-LicenseLog $missingMessage
            [System.Windows.Forms.MessageBox]::Show($missingMessage, "Arquivo master ausente", "OK", "Error") | Out-Null
            return $false
        }

        try {
            # Garantir atributos oculto e somente leitura
            $item = Get-Item -LiteralPath $master.Path -ErrorAction Stop
            $desiredAttributes = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::ReadOnly
            $newAttributes = $item.Attributes -bor $desiredAttributes
            if ($newAttributes -ne $item.Attributes) {
                Set-ItemProperty -Path $master.Path -Name Attributes -Value $newAttributes
                Write-LicenseLog "Atributos aplicados (oculto e somente leitura): $($master.Path)"
            }
        }
        catch {
            $attrMessage = "ERRO ao ler ou aplicar atributos no arquivo master $($master.Name): $($_.Exception.Message)"
            Write-LicenseLog $attrMessage
            [System.Windows.Forms.MessageBox]::Show($attrMessage, "Erro ao proteger masters", "OK", "Error") | Out-Null
            return $false
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
    return $true
}

function Protect-PackageFiles {
    param(
        [string]$PackageRoot,
        [string]$MainEntry
    )

    $hiddenFlag = [System.IO.FileAttributes]::Hidden
    $readOnlyFlag = [System.IO.FileAttributes]::ReadOnly

    Get-ChildItem -Path $PackageRoot -File -Recurse | ForEach-Object {
        $file = $_

        if ($file.Name -ieq $MainEntry) {
            return
        }

        $newAttributes = $file.Attributes -bor $hiddenFlag -bor $readOnlyFlag

        if ($newAttributes -ne $file.Attributes) {
            try {
                Set-ItemProperty -Path $file.FullName -Name Attributes -Value $newAttributes
                Write-LicenseLog "Arquivo encapsulado (oculto/somente leitura): $($file.FullName)"
            }
            catch {
                Write-LicenseLog "Aviso: nao foi possivel encapsular $($file.FullName): $($_.Exception.Message)"
            }
        }
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
    $scriptPath = Join-Path (Split-Path $PSCommandPath) "Delete-IndividualLicense.ps1"

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

    # Criar acao com parametro LicenseId
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -LicenseId `"$LicenseId`""

    # Criar trigger para data de expiracao
    $trigger = New-ScheduledTaskTrigger -Once -At $ExpiryDate

    # Criar principal
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Configuracoes
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Registrar tarefa
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Remocao automatica de licenca PRIMAVERA (ID: $LicenseId) em $($ExpiryDate.ToString('dd/MM/yyyy HH:mm'))" | Out-Null
        Write-LicenseLog "Tarefa agendada criada: $taskName para $($ExpiryDate.ToString('dd/MM/yyyy HH:mm'))"
        return $true
    }
    catch {
        Write-LicenseLog "ERRO ao criar tarefa agendada: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Wizard GUI

function Show-LicensingWizard {
    # Criar formulario principal
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Assistente de Licenciamento PRIMAVERA"
    $form.Size = New-Object System.Drawing.Size(700, 550)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::White

    # Variavel para armazenar o passo atual
    $currentStep = 0
    $totalSteps = 5

    # Dados coletados
    $script:wizardData = @{
        CompanyName = ""
        NIF = ""
        Email = ""
        Address = ""
        Period = "6m"
    }

    #region Header
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(700, 80)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = $ColorPrimary
    $form.Controls.Add($headerPanel)

    $headerTitle = New-Object System.Windows.Forms.Label
    $headerTitle.Text = "Assistente de Licenciamento"
    $headerTitle.Location = New-Object System.Drawing.Point(20, 15)
    $headerTitle.Size = New-Object System.Drawing.Size(660, 30)
    $headerTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $headerTitle.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($headerTitle)

    $headerSubtitle = New-Object System.Windows.Forms.Label
    $headerSubtitle.Text = "Sistema PRIMAVERA"
    $headerSubtitle.Location = New-Object System.Drawing.Point(20, 50)
    $headerSubtitle.Size = New-Object System.Drawing.Size(660, 20)
    $headerSubtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $headerSubtitle.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    $headerPanel.Controls.Add($headerSubtitle)
    #endregion

    #region Content Area
    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Size = New-Object System.Drawing.Size(660, 350)
    $contentPanel.Location = New-Object System.Drawing.Point(20, 90)
    $contentPanel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($contentPanel)
    #endregion

    #region Footer
    $footerPanel = New-Object System.Windows.Forms.Panel
    $footerPanel.Size = New-Object System.Drawing.Size(700, 70)
    $footerPanel.Location = New-Object System.Drawing.Point(0, 450)
    $footerPanel.BackColor = $ColorSecondary
    $form.Controls.Add($footerPanel)

    $btnBack = New-Object System.Windows.Forms.Button
    $btnBack.Text = "< Voltar"
    $btnBack.Location = New-Object System.Drawing.Point(380, 20)
    $btnBack.Size = New-Object System.Drawing.Size(90, 35)
    $btnBack.Enabled = $false
    $footerPanel.Controls.Add($btnBack)

    $btnNext = New-Object System.Windows.Forms.Button
    $btnNext.Text = "Avancar >"
    $btnNext.Location = New-Object System.Drawing.Point(480, 20)
    $btnNext.Size = New-Object System.Drawing.Size(100, 35)
    $btnNext.BackColor = $ColorPrimary
    $btnNext.ForeColor = [System.Drawing.Color]::White
    $btnNext.FlatStyle = "Flat"
    $footerPanel.Controls.Add($btnNext)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancelar"
    $btnCancel.Location = New-Object System.Drawing.Point(590, 20)
    $btnCancel.Size = New-Object System.Drawing.Size(90, 35)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $footerPanel.Controls.Add($btnCancel)

    $stepLabel = New-Object System.Windows.Forms.Label
    $stepLabel.Text = "Passo 1 de $totalSteps"
    $stepLabel.Location = New-Object System.Drawing.Point(20, 25)
    $stepLabel.Size = New-Object System.Drawing.Size(200, 25)
    $stepLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $stepLabel.ForeColor = [System.Drawing.Color]::Gray
    $footerPanel.Controls.Add($stepLabel)
    #endregion

    #region Paginas do Wizard

    # Pagina 1: Boas-vindas
    $page1 = New-Object System.Windows.Forms.Panel
    $page1.Size = $contentPanel.Size
    $page1.Location = New-Object System.Drawing.Point(0, 0)
    $page1.Visible = $true

    $lblWelcome = New-Object System.Windows.Forms.Label
    $lblWelcome.Text = "Bem-vindo ao Assistente de Licenciamento PRIMAVERA"
    $lblWelcome.Location = New-Object System.Drawing.Point(0, 20)
    $lblWelcome.Size = New-Object System.Drawing.Size(660, 35)
    $lblWelcome.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $page1.Controls.Add($lblWelcome)

    $lblWelcomeDesc = New-Object System.Windows.Forms.Label
    $lblWelcomeDesc.Text = @"
Este assistente ira guia-lo atraves do processo de licenciamento do sistema PRIMAVERA.

Durante o processo, voce ira:

   1. Escolher o periodo de validade da licenca

   2. Fornecer as informacoes do cliente

   3. Confirmar os dados inseridos

   4. Instalar a licenca automaticamente

A licenca sera removida automaticamente ao expirar o periodo escolhido.

Clique em 'Avancar' para comecar.
"@
    $lblWelcomeDesc.Location = New-Object System.Drawing.Point(20, 80)
    $lblWelcomeDesc.Size = New-Object System.Drawing.Size(620, 250)
    $lblWelcomeDesc.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $page1.Controls.Add($lblWelcomeDesc)

    $contentPanel.Controls.Add($page1)

    # Pagina 2: Selecao de Periodo
    $page2 = New-Object System.Windows.Forms.Panel
    $page2.Size = $contentPanel.Size
    $page2.Location = New-Object System.Drawing.Point(0, 0)
    $page2.Visible = $false

    $lblPeriodTitle = New-Object System.Windows.Forms.Label
    $lblPeriodTitle.Text = "Selecione o Periodo de Licenca"
    $lblPeriodTitle.Location = New-Object System.Drawing.Point(0, 20)
    $lblPeriodTitle.Size = New-Object System.Drawing.Size(660, 30)
    $lblPeriodTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $page2.Controls.Add($lblPeriodTitle)

    $lblPeriodDesc = New-Object System.Windows.Forms.Label
    $lblPeriodDesc.Text = "Escolha por quanto tempo a licenca deve permanecer ativa:"
    $lblPeriodDesc.Location = New-Object System.Drawing.Point(0, 60)
    $lblPeriodDesc.Size = New-Object System.Drawing.Size(660, 20)
    $lblPeriodDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $page2.Controls.Add($lblPeriodDesc)

    # Radio buttons para periodos
    $radioPeriods = @{}
    $yPos = 100

    foreach ($key in @("3m", "6m", "1a", "2a")) {
        $period = $licensePeriods[$key]

        $radioPanel = New-Object System.Windows.Forms.Panel
        $radioPanel.Size = New-Object System.Drawing.Size(620, 50)
        $radioPanel.Location = New-Object System.Drawing.Point(20, $yPos)
        $radioPanel.BorderStyle = "FixedSingle"
        $radioPanel.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)

        $radio = New-Object System.Windows.Forms.RadioButton
        $radio.Text = $period.Label
        $radio.Location = New-Object System.Drawing.Point(10, 10)
        $radio.Size = New-Object System.Drawing.Size(150, 25)
        $radio.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $radio.Tag = $key
        $radioPanel.Controls.Add($radio)

        $radioDesc = New-Object System.Windows.Forms.Label
        $radioDesc.Text = $period.Description
        $radioDesc.Location = New-Object System.Drawing.Point(170, 12)
        $radioDesc.Size = New-Object System.Drawing.Size(440, 20)
        $radioDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $radioDesc.ForeColor = [System.Drawing.Color]::Gray
        $radioPanel.Controls.Add($radioDesc)

        $page2.Controls.Add($radioPanel)
        $radioPeriods[$key] = $radio

        if ($key -eq "6m") {
            $radio.Checked = $true
        }

        $yPos += 55
    }

    $contentPanel.Controls.Add($page2)

    # Pagina 3: Informacoes do Cliente
    $page3 = New-Object System.Windows.Forms.Panel
    $page3.Size = $contentPanel.Size
    $page3.Location = New-Object System.Drawing.Point(0, 0)
    $page3.Visible = $false

    $lblClientTitle = New-Object System.Windows.Forms.Label
    $lblClientTitle.Text = "Informacoes do Cliente"
    $lblClientTitle.Location = New-Object System.Drawing.Point(0, 20)
    $lblClientTitle.Size = New-Object System.Drawing.Size(660, 30)
    $lblClientTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $page3.Controls.Add($lblClientTitle)

    $lblClientDesc = New-Object System.Windows.Forms.Label
    $lblClientDesc.Text = "Preencha as informacoes do cliente que esta sendo licenciado:"
    $lblClientDesc.Location = New-Object System.Drawing.Point(0, 60)
    $lblClientDesc.Size = New-Object System.Drawing.Size(660, 20)
    $lblClientDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $page3.Controls.Add($lblClientDesc)

    $yPos = 100

    # Nome da Empresa
    $lblCompany = New-Object System.Windows.Forms.Label
    $lblCompany.Text = "Nome da Empresa: *"
    $lblCompany.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblCompany.Size = New-Object System.Drawing.Size(200, 20)
    $lblCompany.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $page3.Controls.Add($lblCompany)

    $txtCompany = New-Object System.Windows.Forms.TextBox
    $txtCompany.Location = New-Object System.Drawing.Point(20, $yPos + 25)
    $txtCompany.Size = New-Object System.Drawing.Size(620, 25)
    $txtCompany.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $page3.Controls.Add($txtCompany)

    $yPos += 65

    # NIF
    $lblNIF = New-Object System.Windows.Forms.Label
    $lblNIF.Text = "NIF (9 digitos): *"
    $lblNIF.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblNIF.Size = New-Object System.Drawing.Size(200, 20)
    $lblNIF.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $page3.Controls.Add($lblNIF)

    $txtNIF = New-Object System.Windows.Forms.TextBox
    $txtNIF.Location = New-Object System.Drawing.Point(20, $yPos + 25)
    $txtNIF.Size = New-Object System.Drawing.Size(300, 25)
    $txtNIF.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $txtNIF.MaxLength = 9
    $page3.Controls.Add($txtNIF)

    $yPos += 65

    # Email
    $lblEmail = New-Object System.Windows.Forms.Label
    $lblEmail.Text = "Email: *"
    $lblEmail.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblEmail.Size = New-Object System.Drawing.Size(200, 20)
    $lblEmail.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $page3.Controls.Add($lblEmail)

    $txtEmail = New-Object System.Windows.Forms.TextBox
    $txtEmail.Location = New-Object System.Drawing.Point(20, $yPos + 25)
    $txtEmail.Size = New-Object System.Drawing.Size(620, 25)
    $txtEmail.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $page3.Controls.Add($txtEmail)

    $yPos += 65

    # Morada
    $lblAddress = New-Object System.Windows.Forms.Label
    $lblAddress.Text = "Morada: *"
    $lblAddress.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblAddress.Size = New-Object System.Drawing.Size(200, 20)
    $lblAddress.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $page3.Controls.Add($lblAddress)

    $txtAddress = New-Object System.Windows.Forms.TextBox
    $txtAddress.Location = New-Object System.Drawing.Point(20, $yPos + 25)
    $txtAddress.Size = New-Object System.Drawing.Size(620, 60)
    $txtAddress.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $txtAddress.Multiline = $true
    $page3.Controls.Add($txtAddress)

    $contentPanel.Controls.Add($page3)

    # Pagina 4: Confirmacao
    $page4 = New-Object System.Windows.Forms.Panel
    $page4.Size = $contentPanel.Size
    $page4.Location = New-Object System.Drawing.Point(0, 0)
    $page4.Visible = $false

    $lblConfirmTitle = New-Object System.Windows.Forms.Label
    $lblConfirmTitle.Text = "Confirme os Dados"
    $lblConfirmTitle.Location = New-Object System.Drawing.Point(0, 20)
    $lblConfirmTitle.Size = New-Object System.Drawing.Size(660, 30)
    $lblConfirmTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $page4.Controls.Add($lblConfirmTitle)

    $lblConfirmDesc = New-Object System.Windows.Forms.Label
    $lblConfirmDesc.Text = "Verifique se todas as informacoes estao corretas antes de prosseguir:"
    $lblConfirmDesc.Location = New-Object System.Drawing.Point(0, 60)
    $lblConfirmDesc.Size = New-Object System.Drawing.Size(660, 20)
    $lblConfirmDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $page4.Controls.Add($lblConfirmDesc)

    $txtConfirmSummary = New-Object System.Windows.Forms.TextBox
    $txtConfirmSummary.Location = New-Object System.Drawing.Point(20, 100)
    $txtConfirmSummary.Size = New-Object System.Drawing.Size(620, 220)
    $txtConfirmSummary.Multiline = $true
    $txtConfirmSummary.ReadOnly = $true
    $txtConfirmSummary.Font = New-Object System.Drawing.Font("Consolas", 9)
    $txtConfirmSummary.ScrollBars = "Vertical"
    $txtConfirmSummary.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
    $page4.Controls.Add($txtConfirmSummary)

    $contentPanel.Controls.Add($page4)

    # Pagina 5: Instalacao/Progresso
    $page5 = New-Object System.Windows.Forms.Panel
    $page5.Size = $contentPanel.Size
    $page5.Location = New-Object System.Drawing.Point(0, 0)
    $page5.Visible = $false

    $lblProgressTitle = New-Object System.Windows.Forms.Label
    $lblProgressTitle.Text = "Instalando Licenca..."
    $lblProgressTitle.Location = New-Object System.Drawing.Point(0, 80)
    $lblProgressTitle.Size = New-Object System.Drawing.Size(660, 30)
    $lblProgressTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $lblProgressTitle.TextAlign = "MiddleCenter"
    $page5.Controls.Add($lblProgressTitle)

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(130, 150)
    $progressBar.Size = New-Object System.Drawing.Size(400, 30)
    $progressBar.Style = "Marquee"
    $progressBar.MarqueeAnimationSpeed = 30
    $page5.Controls.Add($progressBar)

    $lblProgressStatus = New-Object System.Windows.Forms.Label
    $lblProgressStatus.Text = "Inicializando..."
    $lblProgressStatus.Location = New-Object System.Drawing.Point(0, 200)
    $lblProgressStatus.Size = New-Object System.Drawing.Size(660, 25)
    $lblProgressStatus.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblProgressStatus.TextAlign = "MiddleCenter"
    $lblProgressStatus.ForeColor = [System.Drawing.Color]::Gray
    $page5.Controls.Add($lblProgressStatus)

    $txtProgressLog = New-Object System.Windows.Forms.TextBox
    $txtProgressLog.Location = New-Object System.Drawing.Point(80, 240)
    $txtProgressLog.Size = New-Object System.Drawing.Size(500, 80)
    $txtProgressLog.Multiline = $true
    $txtProgressLog.ReadOnly = $true
    $txtProgressLog.Font = New-Object System.Drawing.Font("Consolas", 8)
    $txtProgressLog.ScrollBars = "Vertical"
    $txtProgressLog.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
    $page5.Controls.Add($txtProgressLog)

    $contentPanel.Controls.Add($page5)

    #endregion

    #region Navegacao

    function Show-Page {
        param([int]$PageNumber)

        # Esconder todas as paginas
        $page1.Visible = $false
        $page2.Visible = $false
        $page3.Visible = $false
        $page4.Visible = $false
        $page5.Visible = $false

        # Mostrar pagina especifica
        switch ($PageNumber) {
            0 {
                $page1.Visible = $true
                $headerSubtitle.Text = "Bem-vindo"
                $btnBack.Enabled = $false
                $btnNext.Text = "Avancar >"
                $btnNext.Enabled = $true
            }
            1 {
                $page2.Visible = $true
                $headerSubtitle.Text = "Selecao de Periodo"
                $btnBack.Enabled = $true
                $btnNext.Text = "Avancar >"
                $btnNext.Enabled = $true
            }
            2 {
                $page3.Visible = $true
                $headerSubtitle.Text = "Informacoes do Cliente"
                $btnBack.Enabled = $true
                $btnNext.Text = "Avancar >"
                $btnNext.Enabled = $true
            }
            3 {
                $page4.Visible = $true
                $headerSubtitle.Text = "Confirmacao"
                $btnBack.Enabled = $true
                $btnNext.Text = "Instalar"
                $btnNext.Enabled = $true

                # Atualizar resumo
                $selectedPeriod = ""
                foreach ($radio in $radioPeriods.Values) {
                    if ($radio.Checked) {
                        $selectedPeriod = $radio.Tag
                        break
                    }
                }

                $periodInfo = $licensePeriods[$selectedPeriod]
                $startDate = Get-Date
                $expiryDate = $startDate.AddDays($periodInfo.Days)

                $summary = @"
========================================
RESUMO DO LICENCIAMENTO
========================================

CLIENTE:
  Nome da Empresa: $($txtCompany.Text)
  NIF: $($txtNIF.Text)
  Email: $($txtEmail.Text)
  Morada: $($txtAddress.Text)

LICENCA:
  Periodo: $($periodInfo.Label) ($($periodInfo.Days) dias)
  Data de Inicio: $($startDate.ToString('dd/MM/yyyy HH:mm'))
  Data de Expiracao: $($expiryDate.ToString('dd/MM/yyyy HH:mm'))

INFORMACOES:
  - Os arquivos serao copiados automaticamente
  - Uma tarefa sera agendada para remover a licenca
  - A remocao ocorrera em: $($expiryDate.ToString('dd/MM/yyyy HH:mm'))

========================================
"@
                $txtConfirmSummary.Text = $summary
            }
            4 {
                $page5.Visible = $true
                $headerSubtitle.Text = "Instalacao"
                $btnBack.Enabled = $false
                $btnNext.Enabled = $false
                $btnCancel.Enabled = $false

                # Executar instalacao
                Install-License
            }
        }

        $stepLabel.Text = "Passo $($PageNumber + 1) de $totalSteps"
    }

    $btnNext.Add_Click({
        if ($currentStep -eq 1) {
            # Salvar periodo selecionado
            foreach ($radio in $radioPeriods.Values) {
                if ($radio.Checked) {
                    $script:wizardData.Period = $radio.Tag
                    break
                }
            }
        }
        elseif ($currentStep -eq 2) {
            # Validar dados do cliente
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

            # Salvar dados
            $script:wizardData.CompanyName = $txtCompany.Text.Trim()
            $script:wizardData.NIF = $txtNIF.Text.Trim()
            $script:wizardData.Email = $txtEmail.Text.Trim()
            $script:wizardData.Address = $txtAddress.Text.Trim()
        }
        elseif ($currentStep -eq 3) {
            # Ir para instalacao
            $currentStep++
            Show-Page $currentStep
            return
        }

        if ($currentStep -lt $totalSteps - 1) {
            $currentStep++
            Show-Page $currentStep
        }
    })

    $btnBack.Add_Click({
        if ($currentStep -gt 0) {
            $currentStep--
            Show-Page $currentStep
        }
    })

    #endregion

    #region Funcao de Instalacao

    function Install-License {
        $form.Refresh()

        function Update-Progress {
            param([string]$Status, [string]$Log)
            $lblProgressStatus.Text = $Status
            if ($Log) {
                $txtProgressLog.AppendText("$Log`r`n")
            }
            $form.Refresh()
            Start-Sleep -Milliseconds 500
        }

        try {
            Update-Progress "Inicializando sistema..." "Iniciando processo de licenciamento..."

            # Carregar base de dados
            Update-Progress "Carregando base de dados..." "Carregando licenses.json..."
            $db = Get-LicenseDatabase

            # Gerar ID de licenca
            Update-Progress "Gerando ID de licenca..." "Gerando identificador unico..."
            $licenseId = New-LicenseId -Database $db
            Update-Progress "ID de licenca gerado" "ID: $licenseId"

            # Calcular datas
            $startDate = Get-Date
            $periodInfo = $licensePeriods[$script:wizardData.Period]
            $expiryDate = $startDate.AddDays($periodInfo.Days)

            Update-Progress "Calculando datas..." "Periodo: $($periodInfo.Label) | Expira em: $($expiryDate.ToString('dd/MM/yyyy'))"

            # Obter caminhos de destino
            Update-Progress "Verificando diretorios..." "Localizando instalacao PRIMAVERA..."
            $targetPaths = Get-TargetPaths

            # Copiar arquivos de licenca
            Update-Progress "Copiando arquivos de licenca..." "Copiando Primavera.hlf e PRILIC.lic..."
            $copiedFiles = Copy-LicenseFiles -LicenseId $licenseId -TargetPaths $targetPaths
            Update-Progress "Arquivos copiados" "$($copiedFiles.Count) arquivo(s) copiado(s) com sucesso"

            # Agendar remocao automatica
            Update-Progress "Agendando remocao automatica..." "Criando tarefa agendada..."
            $scheduled = Schedule-LicenseExpiry -LicenseId $licenseId -ExpiryDate $expiryDate

            if ($scheduled) {
                Update-Progress "Agendamento concluido" "Tarefa agendada para $($expiryDate.ToString('dd/MM/yyyy HH:mm'))"
            }
            else {
                Update-Progress "Aviso: Agendamento nao criado" "AVISO: Nao foi possivel agendar remocao automatica"
            }

            # Criar registro de licenca
            Update-Progress "Salvando informacoes..." "Registrando licenca no banco de dados..."
            $license = @{
                licenseId = $licenseId
                client = @{
                    companyName = $script:wizardData.CompanyName
                    nif = $script:wizardData.NIF
                    email = $script:wizardData.Email
                    address = $script:wizardData.Address
                }
                licensing = @{
                    startDate = $startDate.ToString("o")
                    period = $script:wizardData.Period
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
                        details = "Licenca criada via Wizard. Periodo: $($periodInfo.Label)"
                    }
                )
            }

            # Adicionar a base de dados
            $db.licenses += $license
            Save-LicenseDatabase -Database $db

            Update-Progress "Concluido!" "Licenciamento concluido com sucesso!"

            Start-Sleep -Seconds 2

            # Mostrar mensagem de sucesso
            $lblProgressTitle.Text = "Licenciamento Concluido!"
            $lblProgressTitle.ForeColor = $ColorSuccess
            $lblProgressStatus.Text = "Todos os passos foram concluidos com sucesso!"
            $progressBar.Style = "Continuous"
            $progressBar.Value = 100

            $btnNext.Text = "Finalizar"
            $btnNext.Enabled = $true
            $btnNext.Add_Click({
                $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $form.Close()
            })

            # Mostrar resumo final
            $finalMessage = @"
========================================
LICENCIAMENTO CONCLUIDO COM SUCESSO!
========================================

ID da Licenca: $licenseId
Cliente: $($script:wizardData.CompanyName)
NIF: $($script:wizardData.NIF)

Periodo: $($periodInfo.Label)
Inicio: $($startDate.ToString('dd/MM/yyyy HH:mm'))
Expiracao: $($expiryDate.ToString('dd/MM/yyyy HH:mm'))

Arquivos instalados: $($copiedFiles.Count)
Remocao automatica: $(if ($scheduled) { "Agendada" } else { "Nao agendada" })

Os arquivos de licenca foram instalados com sucesso.
A licenca sera removida automaticamente em $($expiryDate.ToString('dd/MM/yyyy')).

Clique em 'Finalizar' para sair.
"@

            [System.Windows.Forms.MessageBox]::Show($finalMessage, "Sucesso", "OK", "Information")
        }
        catch {
            $lblProgressTitle.Text = "Erro na Instalacao"
            $lblProgressTitle.ForeColor = $ColorError
            $lblProgressStatus.Text = "Ocorreu um erro durante a instalacao"
            $progressBar.Visible = $false

            $txtProgressLog.AppendText("`r`nERRO: $($_.Exception.Message)`r`n")

            [System.Windows.Forms.MessageBox]::Show(
                "Erro ao instalar licenca:`n`n$($_.Exception.Message)",
                "Erro",
                "OK",
                "Error"
            )

            $btnCancel.Enabled = $true
        }
    }

    #endregion

    # Mostrar primeira pagina
    Show-Page 0

    # Mostrar formulario
    $result = $form.ShowDialog()

    return $result
}

#endregion

#region Main

# Inicializar sistema
$initialized = Initialize-LicenseSystem

if (-not $initialized) {
    Write-LicenseLog "Inicializacao interrompida: masters ausentes ou inacessiveis."
    exit 1
}

Write-LicenseLog "========================================="
Write-LicenseLog "Iniciando Wizard de Licenciamento PRIMAVERA"

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

# Mostrar wizard
$result = Show-LicensingWizard

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    Write-LicenseLog "Wizard concluido com sucesso"
}
else {
    Write-LicenseLog "Wizard cancelado pelo usuario"
}

Write-LicenseLog "========================================="

#endregion
