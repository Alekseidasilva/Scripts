# Script para criar executavel (.exe) do Wizard de Licenciamento PRIMAVERA
# Usa IExpress (nativo do Windows) para criar arquivo auto-extraivel
# Gera um .exe profissional com todos os arquivos embutidos

#Requires -RunAsAdministrator

param(
    [string]$OutputPath = ".\SETUP-PRIMAVERA-WIZARD.exe",
    [string]$ClientName = "",
    [ValidateSet("Wizard", "Simple")]
    [string]$InterfaceType = "Wizard"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "GERADOR DE EXECUTAVEL (.EXE) - PRIMAVERA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$scriptRoot = Split-Path -Parent $PSCommandPath

# Determinar arquivos baseado no tipo de interface
if ($InterfaceType -eq "Wizard") {
    Write-Host "Tipo de Interface: WIZARD (Profissional)" -ForegroundColor Green
    $requiredFiles = @(
        "LICENCIAR-WIZARD.bat",
        "License-Wizard.ps1",
        "Delete-IndividualLicense.ps1",
        "Primavera.hlf",
        "PRILIC.lic"
    )
    $launcherFile = "LICENCIAR-WIZARD.bat"
    $setupTitle = "Setup Wizard - Licenciamento PRIMAVERA"
}
else {
    Write-Host "Tipo de Interface: FORMULARIO SIMPLES" -ForegroundColor Green
    $requiredFiles = @(
        "LICENCIAR.bat",
        "License-Primavera.ps1",
        "Delete-IndividualLicense.ps1",
        "Primavera.hlf",
        "PRILIC.lic"
    )
    $launcherFile = "LICENCIAR.bat"
    $setupTitle = "Setup - Licenciamento PRIMAVERA"
}

Write-Host ""

# Verificar arquivos obrigatorios
Write-Host "Verificando arquivos necessarios..." -ForegroundColor Yellow
$missing = @()

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
    Write-Host "ERRO: Arquivos necessarios nao encontrados!" -ForegroundColor Red
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
Write-Host "Todos os arquivos encontrados!" -ForegroundColor Green
Write-Host ""

# Criar diretorio temporario para trabalho
$tempDir = Join-Path $env:TEMP "PrimaveraSetupBuilder_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-Host "Diretorio temporario criado: $tempDir" -ForegroundColor Gray
Write-Host ""

try {
    # Copiar arquivos necessarios para o diretorio temporario
    Write-Host "Preparando arquivos..." -ForegroundColor Yellow
    foreach ($file in $requiredFiles) {
        $sourcePath = Join-Path $scriptRoot $file
        $destPath = Join-Path $tempDir $file
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "  Copiado: $file" -ForegroundColor Gray
    }
    Write-Host ""

    # Criar script de instalacao/launcher
    Write-Host "Criando launcher..." -ForegroundColor Yellow

    $clientInfo = if ($ClientName) { " - $ClientName" } else { "" }

    $launcherScript = @"
@echo off
:: ====================================================================
:: Setup Auto-Extraivel - Licenciamento PRIMAVERA
:: Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")$clientInfo
:: ====================================================================

echo.
echo =========================================
echo SETUP - LICENCIAMENTO PRIMAVERA
echo =========================================
echo.
echo Extraindo arquivos...
echo.

:: Mudar para o diretorio onde o executavel esta
cd /d "%~dp0"

:: Verificar se esta executando como Administrador
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo ========================================
    echo AVISO: Privilegios de Administrador necessarios!
    echo ========================================
    echo.
    echo Este setup precisa ser executado como Administrador.
    echo.
    echo Por favor:
    echo 1. Clique com botao direito no arquivo .exe
    echo 2. Selecione "Executar como Administrador"
    echo.
    echo Tentando elevar privilegios...
    echo.

    :: Tentar executar como administrador
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b 1
)

echo.
echo Arquivos extraidos com sucesso!
echo.
echo Iniciando sistema de licenciamento...
echo.
echo =========================================
echo.

:: Executar o launcher apropriado
call "$launcherFile"

echo.
echo =========================================
echo Setup concluido
echo =========================================
echo.

:: Perguntar se deseja manter os arquivos
set /p KEEP_FILES=Deseja manter os arquivos extraidos? (S/N) [N]:

if /i "%KEEP_FILES%"=="S" (
    echo.
    echo Arquivos mantidos em: %~dp0
    echo.
) else (
    echo.
    echo Nota: Os arquivos serao mantidos em: %~dp0
    echo Voce pode remove-los manualmente se desejar.
    echo.
)

pause
"@

    $launcherPath = Join-Path $tempDir "setup_launcher.bat"
    Set-Content -Path $launcherPath -Value $launcherScript -Encoding ASCII
    Write-Host "  Launcher criado: setup_launcher.bat" -ForegroundColor Gray
    Write-Host ""

    # Criar arquivo SED para IExpress
    Write-Host "Gerando configuracao do IExpress..." -ForegroundColor Yellow

    $outputFullPath = [IO.Path]::GetFullPath($OutputPath)
    $sedFile = Join-Path $tempDir "setup.sed"

    # Construir lista de arquivos
    $fileList = @("setup_launcher.bat") + $requiredFiles
    $fileSection = ""
    $fileCount = 0
    foreach ($file in $fileList) {
        $fileSection += "FILE$fileCount=`"$file`"`r`n"
        $fileCount++
    }

    $sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles

[Strings]
InstallPrompt=Deseja instalar o Sistema de Licenciamento PRIMAVERA?
DisplayLicense=
FinishMessage=Setup concluido! O sistema de licenciamento foi extraido com sucesso.
TargetName=$outputFullPath
FriendlyName=$setupTitle$clientInfo
AppLaunched=cmd /c setup_launcher.bat
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="setup_launcher.bat"
$fileSection

[SourceFiles]
SourceFiles0=$tempDir
[SourceFiles0]
%FILE0%=
"@

    # Adicionar arquivos restantes ao SED
    for ($i = 1; $i -lt $fileCount; $i++) {
        $sedContent += "%FILE$i%=`r`n"
    }

    Set-Content -Path $sedFile -Value $sedContent -Encoding ASCII
    Write-Host "  Configuracao criada: setup.sed" -ForegroundColor Gray
    Write-Host ""

    # Executar IExpress para criar o .exe
    Write-Host "Criando executavel (.exe)..." -ForegroundColor Green
    Write-Host "Isso pode levar alguns segundos..." -ForegroundColor Gray
    Write-Host ""

    $iexpressPath = Join-Path $env:SystemRoot "System32\iexpress.exe"

    if (-not (Test-Path $iexpressPath)) {
        throw "IExpress nao encontrado em: $iexpressPath"
    }

    # Executar IExpress em modo silencioso
    $process = Start-Process -FilePath $iexpressPath -ArgumentList "/N `"$sedFile`"" -Wait -PassThru -WindowStyle Hidden

    if ($process.ExitCode -ne 0) {
        throw "IExpress falhou com codigo de saida: $($process.ExitCode)"
    }

    # Verificar se o arquivo foi criado
    if (-not (Test-Path $outputFullPath)) {
        throw "Arquivo executavel nao foi criado: $outputFullPath"
    }

    Write-Host "Executavel criado com sucesso!" -ForegroundColor Green
    Write-Host ""

    # Limpar diretorio temporario
    Write-Host "Limpando arquivos temporarios..." -ForegroundColor Yellow
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ""

    # Resumo
    $fileSize = (Get-Item $outputFullPath).Length

    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "EXECUTAVEL CRIADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Arquivo gerado:" -ForegroundColor Cyan
    Write-Host "  $outputFullPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Tamanho:" -ForegroundColor Cyan
    Write-Host "  $(($fileSize / 1KB).ToString('N2')) KB ($(($fileSize / 1MB).ToString('N2')) MB)" -ForegroundColor White
    Write-Host ""
    Write-Host "Tipo de Interface:" -ForegroundColor Cyan
    if ($InterfaceType -eq "Wizard") {
        Write-Host "  WIZARD - Interface profissional com 5 etapas" -ForegroundColor White
    }
    else {
        Write-Host "  FORMULARIO SIMPLES - Uma tela rapida" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Arquivos incluidos:" -ForegroundColor Cyan
    foreach ($file in $requiredFiles) {
        Write-Host "  - $file" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "INSTRUCOES DE USO" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Para o Tecnico:" -ForegroundColor Yellow
    Write-Host "1. Copie o arquivo .exe para um PEN drive ou envie por email" -ForegroundColor White
    Write-Host "2. No computador do cliente, execute o .exe como Administrador" -ForegroundColor White
    Write-Host "3. O sistema ira:" -ForegroundColor White
    Write-Host "   - Extrair automaticamente os arquivos" -ForegroundColor Gray
    Write-Host "   - Verificar privilegios de Administrador" -ForegroundColor Gray
    if ($InterfaceType -eq "Wizard") {
        Write-Host "   - Abrir o wizard de licenciamento (5 etapas)" -ForegroundColor Gray
    }
    else {
        Write-Host "   - Abrir o formulario de licenciamento" -ForegroundColor Gray
    }
    Write-Host "   - Permitir escolher o periodo de licenca" -ForegroundColor Gray
    Write-Host "   - Instalar e agendar a exclusao automatica" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Vantagens do .exe:" -ForegroundColor Yellow
    Write-Host "  + Nao precisa descompactar manualmente" -ForegroundColor Green
    Write-Host "  + Parece mais profissional" -ForegroundColor Green
    Write-Host "  + Mais facil de distribuir" -ForegroundColor Green
    Write-Host "  + Funciona em qualquer Windows" -ForegroundColor Green
    Write-Host "  + Verifica privilegios automaticamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "A licenca sera removida automaticamente ao expirar!" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ERRO ao criar executavel:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""

    # Limpar diretorio temporario em caso de erro
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    exit 1
}

Write-Host "Pressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
