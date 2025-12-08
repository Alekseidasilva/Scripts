@echo off
:: ====================================================================
:: Setup do Sistema de Licenciamento PRIMAVERA
:: Cria estrutura de pastas necessaria
:: ====================================================================

:: Verificar se esta executando como Administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Executando com privilegios de Administrador...
    echo.
) else (
    echo.
    echo ========================================
    echo ERRO: Privilegios de Administrador necessarios!
    echo ========================================
    echo.
    echo Este script precisa ser executado como Administrador.
    echo.
    echo Por favor:
    echo 1. Clique com botao direito em SETUP-LICENSING.bat
    echo 2. Selecione "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

:: Mudar para o diretorio onde o script esta localizado
cd /d "%~dp0"

echo ========================================
echo SETUP - Sistema de Licenciamento
echo ========================================
echo.

:: Verificar se o arquivo PowerShell existe
if not exist "Setup-LicensingSystem.ps1" (
    echo ERRO: Setup-LicensingSystem.ps1 nao encontrado!
    echo.
    pause
    exit /b 1
)

:: Executar o script PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-LicensingSystem.ps1"

echo.
