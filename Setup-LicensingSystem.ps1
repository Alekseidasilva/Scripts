# Script de Configuracao Inicial do Sistema de Licenciamento PRIMAVERA
# Cria toda a estrutura de diretorios necessaria

#Requires -RunAsAdministrator

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "SETUP - Sistema de Licenciamento PRIMAVERA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Diretorios a criar
$scriptRoot = Split-Path -Parent $PSCommandPath
$vaultDir = "C:\PrimaveraLicenseVault"
$directories = @(
    "$vaultDir",
    "$vaultDir\Master",
    "$vaultDir\Database",
    "$vaultDir\Backups",
    "$vaultDir\Logs"
)

Write-Host "Criando estrutura de diretorios..." -ForegroundColor Green
Write-Host ""

$created = 0
$existing = 0

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[CRIADO] $dir" -ForegroundColor Green
        $created++
    }
    else {
        Write-Host "[OK]     $dir (ja existe)" -ForegroundColor Yellow
        $existing++
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Estrutura criada com sucesso!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resumo:" -ForegroundColor Cyan
Write-Host "  Diretorios criados: $created" -ForegroundColor White
Write-Host "  Ja existentes: $existing" -ForegroundColor White
Write-Host ""

# Criar arquivo README na pasta Master
$readmeMaster = @"
========================================
PASTA DE ARQUIVOS MASTER DE LICENCA
========================================

INSTRUCOES:

1. Copie os arquivos originais de licenca do PRIMAVERA para esta pasta:

   - Primavera.hlf
   - PRILIC.lic

2. Estes arquivos serao usados como MASTER (originais) e copiados
   para os clientes durante o licenciamento.

3. IMPORTANTE:
   - Mantenha backups destes arquivos em local seguro
   - Nao modifique os arquivos apos copiar para ca
   - Estes arquivos sao essenciais para o sistema funcionar

4. Apos copiar os arquivos, execute:
   LICENCIAR.bat (como Administrador)

========================================
ESTRUTURA ESPERADA:
========================================

C:\PrimaveraLicenseVault\
├── Master\
│   ├── Primavera.hlf   ← COLOQUE AQUI
│   ├── PRILIC.lic      ← COLOQUE AQUI
│   └── README.txt      (este arquivo)
├── Database\           (criado automaticamente)
├── Backups\            (criado automaticamente)
└── Logs\               (criado automaticamente)

========================================
"@

$readmePath = "$vaultDir\Master\README.txt"
$readmeMaster | Set-Content $readmePath

# Copiar automaticamente os arquivos de licenca se estiverem no pacote
$copied = 0
$missing = @()
$packageFiles = @(
    @{ Name = "Primavera.hlf"; Target = "$vaultDir\Master\Primavera.hlf" },
    @{ Name = "PRILIC.lic"; Target = "$vaultDir\Master\PRILIC.lic" }
)

foreach ($file in $packageFiles) {
    $source = Join-Path $scriptRoot $file.Name
    if (Test-Path $source) {
        Copy-Item $source -Destination $file.Target -Force
        Write-Host "[COPIADO] $($file.Name) a partir do pacote" -ForegroundColor Green
        $copied++
    }
    else {
        $missing += $file.Name
        Write-Host "[FALTA] $($file.Name) nao encontrado no pacote" -ForegroundColor Yellow
    }
}

if ($copied -gt 0) {
    Write-Host ""; Write-Host "Arquivos de licenca disponibilizados automaticamente." -ForegroundColor Green
}

if ($missing.Count -gt 0) {
    Write-Host ""; Write-Host "ATENCAO: Copie manualmente os arquivos ausentes para $vaultDir\\Master" -ForegroundColor Yellow
    Write-Host ("Pendentes: " + ($missing -join ", ")) -ForegroundColor Yellow
}

Write-Host ""; Write-Host "Setup concluido!" -ForegroundColor Green
Write-Host ""; Write-Host "Pressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
