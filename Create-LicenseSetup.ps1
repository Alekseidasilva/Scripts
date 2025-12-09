# Script para criar pacote de setup completo de licenciamento PRIMAVERA
# Gera um arquivo executavel autocontido com todos os arquivos necessarios

#Requires -RunAsAdministrator

param(
    [string]$OutputPath = ".\SETUP-LICENCIAMENTO-PRIMAVERA.ps1",
    [string]$ClientName = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "GERADOR DE SETUP DE LICENCIAMENTO PRIMAVERA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Arquivos obrigatorios que devem estar presentes
$requiredFiles = @(
    "LICENCIAR.bat",
    "License-Primavera.ps1",
    "Delete-IndividualLicense.ps1",
    "Primavera.hlf",
    "PRILIC.lic"
)

# Verificar arquivos obrigatorios
Write-Host "Verificando arquivos obrigatorios..." -ForegroundColor Yellow
$missing = @()
$scriptRoot = Split-Path -Parent $PSCommandPath

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $scriptRoot $file
    if (-not (Test-Path $filePath)) {
        $missing += $file
        Write-Host "  [FALTA] $file" -ForegroundColor Red
    }
    else {
        Write-Host "  [OK] $file" -ForegroundColor Green
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "ERRO: Arquivos obrigatorios nao encontrados!" -ForegroundColor Red
    Write-Host "Arquivos faltando:" -ForegroundColor Red
    foreach ($file in $missing) {
        Write-Host "  - $file" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Por favor, certifique-se que todos os arquivos estao no diretorio:" -ForegroundColor Yellow
    Write-Host "  $scriptRoot" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Todos os arquivos obrigatorios encontrados!" -ForegroundColor Green
Write-Host ""

# Criar ZIP temporario com os arquivos necessarios
Write-Host "Criando pacote temporario..." -ForegroundColor Yellow

$tempZip = [IO.Path]::GetTempFileName()
Remove-Item $tempZip -Force
$tempZip = "$tempZip.zip"

# Arquivos a incluir no pacote
$filesToPackage = @(
    "LICENCIAR.bat",
    "License-Primavera.ps1",
    "Delete-IndividualLicense.ps1",
    "Primavera.hlf",
    "PRILIC.lic"
)

$filePaths = $filesToPackage | ForEach-Object { Join-Path $scriptRoot $_ }
Compress-Archive -Path $filePaths -DestinationPath $tempZip -Force

Write-Host "Pacote temporario criado" -ForegroundColor Green
Write-Host ""

# Converter ZIP para Base64
Write-Host "Codificando pacote..." -ForegroundColor Yellow
$zipBytes = [IO.File]::ReadAllBytes($tempZip)
$zipBase64 = [Convert]::ToBase64String($zipBytes)
Write-Host "Pacote codificado ($(($zipBase64.Length / 1024).ToString('N2')) KB)" -ForegroundColor Green
Write-Host ""

# Gerar nome do cliente se fornecido
$clientInfo = if ($ClientName) { " - $ClientName" } else { "" }

# Criar script auto-extraivel
$setupScript = @"
<#
.SYNOPSIS
Setup de Licenciamento PRIMAVERA - Auto-Extraivel

.DESCRIPTION
Este e um pacote auto-extraivel que contem todos os arquivos necessarios
para o licenciamento do sistema PRIMAVERA.

Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")$clientInfo

.NOTES
Ao executar este script:
1. Os arquivos serao extraidos para uma pasta temporaria
2. O sistema de licenciamento sera iniciado automaticamente
3. Voce podera escolher o periodo de licenca (3m, 6m, 1a, 2a)
4. Os arquivos de licenca serao copiados para o sistema PRIMAVERA
5. A exclusao automatica sera agendada conforme o periodo escolhido

IMPORTANTE: Execute este script como Administrador!
#>

#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "SETUP DE LICENCIAMENTO PRIMAVERA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Criar pasta temporaria unica
`$timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
`$extractRoot = Join-Path `$env:TEMP "PrimaveraLicenseSetup-`$timestamp"
`$zipPath = Join-Path `$extractRoot 'package.zip'

Write-Host "Criando pasta temporaria..." -ForegroundColor Yellow
Write-Host "  `$extractRoot" -ForegroundColor Gray
New-Item -ItemType Directory -Path `$extractRoot -Force | Out-Null
Write-Host ""

Write-Host "Extraindo arquivos de licenciamento..." -ForegroundColor Yellow

# Decodificar e salvar ZIP
`$zipBase64 = '$zipBase64'
[IO.File]::WriteAllBytes(`$zipPath, [Convert]::FromBase64String(`$zipBase64))

# Extrair arquivos
Expand-Archive -LiteralPath `$zipPath -DestinationPath `$extractRoot -Force
Remove-Item `$zipPath -Force

Write-Host "Arquivos extraidos com sucesso!" -ForegroundColor Green
Write-Host ""

# Verificar se LICENCIAR.bat existe
`$licenciarBat = Join-Path `$extractRoot 'LICENCIAR.bat'
if (-not (Test-Path `$licenciarBat)) {
    Write-Host "ERRO: LICENCIAR.bat nao encontrado apos extracao!" -ForegroundColor Red
    Write-Host "Pasta de extracao: `$extractRoot" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Iniciando sistema de licenciamento..." -ForegroundColor Green
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Executar LICENCIAR.bat
`$process = Start-Process -FilePath `$licenciarBat -WorkingDirectory `$extractRoot -PassThru -Wait

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Processo de licenciamento concluido" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Perguntar se deseja manter os arquivos temporarios
`$response = Read-Host "Deseja manter os arquivos temporarios? (S/N) [N]"
if (`$response -eq 'S' -or `$response -eq 's') {
    Write-Host ""
    Write-Host "Arquivos mantidos em: `$extractRoot" -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "Limpando arquivos temporarios..." -ForegroundColor Yellow
    try {
        Remove-Item -LiteralPath `$extractRoot -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Arquivos temporarios removidos" -ForegroundColor Green
    }
    catch {
        Write-Host "AVISO: Nao foi possivel remover alguns arquivos temporarios" -ForegroundColor Yellow
        Write-Host "  `$extractRoot" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "Pressione qualquer tecla para sair..."
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

exit `$process.ExitCode
"@

# Salvar setup
Write-Host "Gerando arquivo de setup..." -ForegroundColor Yellow
$outputFullPath = [IO.Path]::GetFullPath($OutputPath)
Set-Content -LiteralPath $outputFullPath -Value $setupScript -Encoding UTF8
Write-Host "Setup gerado com sucesso!" -ForegroundColor Green
Write-Host ""

# Limpar arquivo temporario
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue

# Resumo
Write-Host "=========================================" -ForegroundColor Green
Write-Host "SETUP CRIADO COM SUCESSO!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Arquivo gerado:" -ForegroundColor Cyan
Write-Host "  $outputFullPath" -ForegroundColor White
Write-Host ""
Write-Host "Tamanho:" -ForegroundColor Cyan
$fileSize = (Get-Item $outputFullPath).Length
Write-Host "  $(($fileSize / 1KB).ToString('N2')) KB" -ForegroundColor White
Write-Host ""
Write-Host "Arquivos incluidos:" -ForegroundColor Cyan
foreach ($file in $filesToPackage) {
    Write-Host "  - $file" -ForegroundColor White
}
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "INSTRUCOES DE USO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Envie o arquivo para o cliente/tecnico" -ForegroundColor White
Write-Host "2. Execute o arquivo como Administrador" -ForegroundColor White
Write-Host "3. O sistema ira:" -ForegroundColor White
Write-Host "   - Extrair os arquivos automaticamente" -ForegroundColor Gray
Write-Host "   - Abrir o assistente de licenciamento" -ForegroundColor Gray
Write-Host "   - Permitir escolher o periodo (3m, 6m, 1a, 2a)" -ForegroundColor Gray
Write-Host "   - Copiar os arquivos de licenca" -ForegroundColor Gray
Write-Host "   - Agendar a exclusao automatica" -ForegroundColor Gray
Write-Host ""
Write-Host "A licenca sera removida automaticamente ao expirar!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
