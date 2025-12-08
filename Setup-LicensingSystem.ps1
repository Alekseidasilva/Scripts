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

# Avisar que os arquivos serao usados diretamente do pacote
Write-Host "Os arquivos de licenca serao usados diretamente do pacote (sem copia para C:\\PrimaveraLicenseVault)." -ForegroundColor Cyan

Write-Host ""; Write-Host "Setup concluido!" -ForegroundColor Green
Write-Host ""; Write-Host "Pressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
