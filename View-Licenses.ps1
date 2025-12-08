# Sistema de Gestao de Licencas PRIMAVERA
# Script para visualizar licencas ativas e historico

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Configuracao

$databaseFile = "C:\PrimaveraLicenseVault\Database\licenses.json"

#endregion

#region Funcoes Helper

function Get-LicenseDatabase {
    if (Test-Path $databaseFile) {
        return Get-Content $databaseFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Format-LicenseStatus {
    param([datetime]$ExpiryDate)

    $now = Get-Date
    $daysRemaining = ($ExpiryDate - $now).Days

    if ($daysRemaining -lt 0) {
        return @{ Status = "EXPIRADA"; Color = "Red"; Days = 0 }
    }
    elseif ($daysRemaining -le 7) {
        return @{ Status = "EXPIRA EM BREVE"; Color = "Orange"; Days = $daysRemaining }
    }
    elseif ($daysRemaining -le 30) {
        return @{ Status = "ATIVA (< 1 mes)"; Color = "Yellow"; Days = $daysRemaining }
    }
    else {
        return @{ Status = "ATIVA"; Color = "Green"; Days = $daysRemaining }
    }
}

#endregion

#region GUI

function Show-LicensesGrid {
    param($Licenses)

    # Criar formulario
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Licencas PRIMAVERA - Visualizacao"
    $form.Size = New-Object System.Drawing.Size(900, 600)
    $form.StartPosition = "CenterScreen"

    # Titulo
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "LICENCAS PRIMAVERA ATIVAS"
    $lblTitle.Location = New-Object System.Drawing.Point(10, 10)
    $lblTitle.Size = New-Object System.Drawing.Size(860, 30)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $lblTitle.TextAlign = "MiddleCenter"
    $form.Controls.Add($lblTitle)

    # DataGridView
    $dataGrid = New-Object System.Windows.Forms.DataGridView
    $dataGrid.Location = New-Object System.Drawing.Point(10, 50)
    $dataGrid.Size = New-Object System.Drawing.Size(860, 450)
    $dataGrid.AutoSizeColumnsMode = "Fill"
    $dataGrid.SelectionMode = "FullRowSelect"
    $dataGrid.MultiSelect = $false
    $dataGrid.ReadOnly = $true
    $dataGrid.AllowUserToAddRows = $false
    $dataGrid.RowHeadersVisible = $false
    $form.Controls.Add($dataGrid)

    # Adicionar colunas
    $dataGrid.Columns.Add("ID", "ID Licenca") | Out-Null
    $dataGrid.Columns.Add("Company", "Empresa") | Out-Null
    $dataGrid.Columns.Add("NIF", "NIF") | Out-Null
    $dataGrid.Columns.Add("Period", "Periodo") | Out-Null
    $dataGrid.Columns.Add("StartDate", "Inicio") | Out-Null
    $dataGrid.Columns.Add("ExpiryDate", "Expiracao") | Out-Null
    $dataGrid.Columns.Add("DaysRemaining", "Dias Restantes") | Out-Null
    $dataGrid.Columns.Add("Status", "Estado") | Out-Null

    # Preencher dados
    foreach ($license in $Licenses) {
        $startDate = [datetime]::Parse($license.licensing.startDate)
        $expiryDate = [datetime]::Parse($license.licensing.expiryDate)
        $statusInfo = Format-LicenseStatus -ExpiryDate $expiryDate

        $row = $dataGrid.Rows.Add(
            $license.licenseId,
            $license.client.companyName,
            $license.client.nif,
            $license.licensing.periodLabel,
            $startDate.ToString("dd/MM/yyyy"),
            $expiryDate.ToString("dd/MM/yyyy"),
            $statusInfo.Days,
            $statusInfo.Status
        )

        # Colorir linha baseado no status
        $rowObj = $dataGrid.Rows[$row]
        switch ($statusInfo.Color) {
            "Red" { $rowObj.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightCoral }
            "Orange" { $rowObj.DefaultCellStyle.BackColor = [System.Drawing.Color]::Orange }
            "Yellow" { $rowObj.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightYellow }
            "Green" { $rowObj.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen }
        }
    }

    # Label de resumo
    $lblSummary = New-Object System.Windows.Forms.Label
    $lblSummary.Location = New-Object System.Drawing.Point(10, 510)
    $lblSummary.Size = New-Object System.Drawing.Size(600, 20)
    $lblSummary.Text = "Total de licencas: $($Licenses.Count)"
    $form.Controls.Add($lblSummary)

    # Botao Detalhes
    $btnDetails = New-Object System.Windows.Forms.Button
    $btnDetails.Text = "Ver Detalhes"
    $btnDetails.Location = New-Object System.Drawing.Point(620, 505)
    $btnDetails.Size = New-Object System.Drawing.Size(100, 30)
    $form.Controls.Add($btnDetails)

    $btnDetails.Add_Click({
        if ($dataGrid.SelectedRows.Count -gt 0) {
            $selectedId = $dataGrid.SelectedRows[0].Cells[0].Value
            $selectedLicense = $Licenses | Where-Object { $_.licenseId -eq $selectedId }
            Show-LicenseDetails -License $selectedLicense
        }
    })

    # Botao Fechar
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Fechar"
    $btnClose.Location = New-Object System.Drawing.Point(730, 505)
    $btnClose.Size = New-Object System.Drawing.Size(100, 30)
    $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnClose)

    # Mostrar formulario
    $form.ShowDialog() | Out-Null
}

function Show-LicenseDetails {
    param($License)

    $startDate = [datetime]::Parse($License.licensing.startDate)
    $expiryDate = [datetime]::Parse($License.licensing.expiryDate)
    $statusInfo = Format-LicenseStatus -ExpiryDate $expiryDate

    $details = @"
========================================
DETALHES DA LICENCA
========================================

ID: $($License.licenseId)

CLIENTE:
  Empresa: $($License.client.companyName)
  NIF: $($License.client.nif)
  Email: $($License.client.email)
  Morada: $($License.client.address)

LICENCIAMENTO:
  Periodo: $($License.licensing.periodLabel) ($($License.licensing.periodDays) dias)
  Data de Inicio: $($startDate.ToString('dd/MM/yyyy HH:mm'))
  Data de Expiracao: $($expiryDate.ToString('dd/MM/yyyy HH:mm'))
  Dias Restantes: $($statusInfo.Days)
  Estado: $($statusInfo.Status)
  Remocao Automatica: $(if ($License.licensing.autoRemove) { "Sim" } else { "Nao" })

ARQUIVOS INSTALADOS:
$($License.files | ForEach-Object { "  - $($_.name) em $($_.targetPath)" } | Out-String)

HISTORICO:
$($License.history | ForEach-Object {
    $actionDate = [datetime]::Parse($_.date)
    "  [$($actionDate.ToString('dd/MM/yyyy HH:mm'))] $($_.action) - $($_.details)"
} | Out-String)
========================================
"@

    [System.Windows.Forms.MessageBox]::Show($details, "Detalhes da Licenca", "OK", "Information")
}

#endregion

#region Main

Write-Host "========================================="
Write-Host "Sistema de Visualizacao de Licencas PRIMAVERA"
Write-Host "========================================="
Write-Host ""

# Verificar se base de dados existe
if (-not (Test-Path $databaseFile)) {
    Write-Host "ERRO: Base de dados nao encontrada: $databaseFile" -ForegroundColor Red
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
    Write-Host "Nenhuma licenca encontrada na base de dados." -ForegroundColor Yellow
    [System.Windows.Forms.MessageBox]::Show(
        "Nenhuma licenca encontrada.`n`nUtilize o sistema de licenciamento para criar licencas.",
        "Informacao",
        "OK",
        "Information"
    )
    exit 0
}

Write-Host "Licencas encontradas: $($db.licenses.Count)"
Write-Host ""

# Mostrar estatisticas resumidas
$now = Get-Date
$active = 0
$expiringSoon = 0
$expired = 0

foreach ($license in $db.licenses) {
    $expiryDate = [datetime]::Parse($license.licensing.expiryDate)
    $daysRemaining = ($expiryDate - $now).Days

    if ($daysRemaining -lt 0) {
        $expired++
    }
    elseif ($daysRemaining -le 7) {
        $expiringSoon++
    }
    else {
        $active++
    }
}

Write-Host "Resumo:"
Write-Host "  Ativas: $active" -ForegroundColor Green
Write-Host "  Expiram em breve (7 dias): $expiringSoon" -ForegroundColor Yellow
Write-Host "  Expiradas: $expired" -ForegroundColor Red
Write-Host ""

# Mostrar grid
Show-LicensesGrid -Licenses $db.licenses

#endregion
