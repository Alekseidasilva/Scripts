# Sistema de Gestao de Licencas PRIMAVERA
# Script para renovar licencas existentes

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Configuracao

$databaseFile = "C:\PrimaveraLicenseVault\Database\licenses.json"
$logFile = "C:\PrimaveraLicenseVault\Logs\licensing.log"

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

function Update-LicenseExpiry {
    param(
        [string]$LicenseId,
        [datetime]$NewExpiryDate
    )

    $taskName = "PRIMAVERA_License_Expiry_$LicenseId"
    $scriptPath = Join-Path (Split-Path $PSCommandPath) "Delete-PrimaveraFiles.ps1"

    # Verificar se o script de remocao existe
    if (-not (Test-Path $scriptPath)) {
        Write-LicenseLog "AVISO: Script de remocao nao encontrado: $scriptPath"
        return $false
    }

    # Remover tarefa existente
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Criar nova tarefa com data atualizada
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At $NewExpiryDate
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Remocao automatica de licenca PRIMAVERA (ID: $LicenseId)" | Out-Null
        Write-LicenseLog "Tarefa de expiracao atualizada para: $($NewExpiryDate.ToString('dd/MM/yyyy HH:mm'))"
        return $true
    }
    catch {
        Write-LicenseLog "ERRO ao atualizar tarefa agendada: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region GUI

function Select-LicenseToRenew {
    param($Licenses)

    # Criar formulario
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Renovar Licenca PRIMAVERA"
    $form.Size = New-Object System.Drawing.Size(700, 500)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # Titulo
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "SELECIONE A LICENCA PARA RENOVAR"
    $lblTitle.Location = New-Object System.Drawing.Point(10, 10)
    $lblTitle.Size = New-Object System.Drawing.Size(660, 30)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblTitle.TextAlign = "MiddleCenter"
    $form.Controls.Add($lblTitle)

    # Lista de licencas
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 50)
    $listBox.Size = New-Object System.Drawing.Size(660, 250)
    $listBox.Font = New-Object System.Drawing.Font("Courier New", 9)
    $form.Controls.Add($listBox)

    # Preencher lista
    foreach ($license in $Licenses) {
        $expiryDate = [datetime]::Parse($license.licensing.expiryDate)
        $daysRemaining = ($expiryDate - (Get-Date)).Days
        $status = if ($daysRemaining -lt 0) { "EXPIRADA" } else { "$daysRemaining dias" }

        $item = "{0,-12} | {1,-30} | {2,-10} | {3}" -f $license.licenseId, $license.client.companyName, $license.client.nif, $status
        $listBox.Items.Add($item) | Out-Null
        $listBox.Items[$listBox.Items.Count - 1].Tag = $license.licenseId
    }

    if ($listBox.Items.Count -gt 0) {
        $listBox.SelectedIndex = 0
    }

    # Periodo de renovacao
    $yPos = 320

    $lblPeriod = New-Object System.Windows.Forms.Label
    $lblPeriod.Text = "Periodo de Renovacao:"
    $lblPeriod.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblPeriod.Size = New-Object System.Drawing.Size(200, 20)
    $lblPeriod.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($lblPeriod)

    $yPos += 25

    # Radio buttons
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

    # Botoes
    $btnRenew = New-Object System.Windows.Forms.Button
    $btnRenew.Text = "Renovar"
    $btnRenew.Location = New-Object System.Drawing.Point(470, 420)
    $btnRenew.Size = New-Object System.Drawing.Size(90, 30)
    $btnRenew.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnRenew.ForeColor = [System.Drawing.Color]::White
    $btnRenew.FlatStyle = "Flat"
    $form.Controls.Add($btnRenew)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancelar"
    $btnCancel.Location = New-Object System.Drawing.Point(570, 420)
    $btnCancel.Size = New-Object System.Drawing.Size(90, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    # Evento do botao Renovar
    $btnRenew.Add_Click({
        if ($listBox.SelectedIndex -ge 0) {
            # Obter periodo selecionado
            $selectedPeriod = $null
            foreach ($radio in $radioPeriods.Values) {
                if ($radio.Checked) {
                    $selectedPeriod = $radio.Tag
                    break
                }
            }

            $selectedText = $listBox.SelectedItem
            $selectedId = $selectedText.Split('|')[0].Trim()

            $script:renewalData = @{
                LicenseId = $selectedId
                Period = $selectedPeriod
            }

            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        }
    })

    # Mostrar formulario
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $script:renewalData
    }

    return $null
}

#endregion

#region Main

Write-LicenseLog "========================================="
Write-LicenseLog "Iniciando processo de renovacao de licenca PRIMAVERA"

# Verificar se base de dados existe
if (-not (Test-Path $databaseFile)) {
    Write-LicenseLog "ERRO: Base de dados nao encontrada"
    [System.Windows.Forms.MessageBox]::Show(
        "Base de dados de licencas nao encontrada.`n`nO sistema ainda nao foi inicializado.",
        "Erro",
        "OK",
        "Error"
    )
    exit 1
}

# Carregar base de dados
$db = Get-LicenseDatabase

if ($db.licenses.Count -eq 0) {
    Write-LicenseLog "Nenhuma licenca encontrada"
    [System.Windows.Forms.MessageBox]::Show(
        "Nenhuma licenca encontrada para renovar.",
        "Informacao",
        "OK",
        "Information"
    )
    exit 0
}

# Selecionar licenca para renovar
$renewalData = Select-LicenseToRenew -Licenses $db.licenses

if ($null -eq $renewalData) {
    Write-LicenseLog "Renovacao cancelada pelo usuario"
    exit 0
}

# Encontrar licenca
$license = $db.licenses | Where-Object { $_.licenseId -eq $renewalData.LicenseId }

if ($null -eq $license) {
    Write-LicenseLog "ERRO: Licenca nao encontrada: $($renewalData.LicenseId)"
    exit 1
}

Write-LicenseLog "Renovando licenca: $($renewalData.LicenseId) - $($license.client.companyName)"

# Calcular nova data de expiracao (a partir da data atual ou data de expiracao, o que for mais tarde)
$currentExpiry = [datetime]::Parse($license.licensing.expiryDate)
$now = Get-Date
$baseDate = if ($currentExpiry -gt $now) { $currentExpiry } else { $now }

$periodInfo = $licensePeriods[$renewalData.Period]
$newExpiryDate = $baseDate.AddDays($periodInfo.Days)

Write-LicenseLog "Data de expiracao anterior: $($currentExpiry.ToString('dd/MM/yyyy HH:mm'))"
Write-LicenseLog "Nova data de expiracao: $($newExpiryDate.ToString('dd/MM/yyyy HH:mm'))"
Write-LicenseLog "Periodo adicional: $($periodInfo.Label)"

# Atualizar tarefa agendada
$taskUpdated = Update-LicenseExpiry -LicenseId $renewalData.LicenseId -NewExpiryDate $newExpiryDate

# Atualizar licenca na base de dados
$license.licensing.expiryDate = $newExpiryDate.ToString("o")

# Adicionar ao historico
$historyEntry = @{
    action = "RENEWED"
    date = (Get-Date).ToString("o")
    user = $env:USERNAME
    details = "Licenca renovada por $($periodInfo.Label). Nova expiracao: $($newExpiryDate.ToString('dd/MM/yyyy'))"
}

$license.history += $historyEntry

# Salvar base de dados
Save-LicenseDatabase -Database $db

Write-LicenseLog "Licenca renovada com sucesso"
Write-LicenseLog "========================================="

# Mostrar mensagem de sucesso
$message = @"
RENOVACAO CONCLUIDA COM SUCESSO!

ID da Licenca: $($renewalData.LicenseId)
Cliente: $($license.client.companyName)

Periodo Adicional: $($periodInfo.Label) ($($periodInfo.Days) dias)
Nova Data de Expiracao: $($newExpiryDate.ToString('dd/MM/yyyy HH:mm'))

Tarefa agendada: $(if ($taskUpdated) { "Atualizada" } else { "Nao atualizada" })

A licenca foi renovada com sucesso.
"@

[System.Windows.Forms.MessageBox]::Show($message, "Sucesso", "OK", "Information")

#endregion
