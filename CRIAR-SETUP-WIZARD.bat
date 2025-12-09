@echo off
:: ====================================================================
:: Gerador de Setup Wizard de Licenciamento PRIMAVERA
:: Cria um pacote autocontido com interface wizard profissional
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
    echo 1. Clique com botao direito em CRIAR-SETUP-WIZARD.bat
    echo 2. Selecione "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

:: Mudar para o diretorio onde o script esta localizado
cd /d "%~dp0"

echo ========================================
echo GERADOR DE SETUP WIZARD
echo ========================================
echo.

:: Verificar se o arquivo PowerShell existe
if not exist "Create-WizardSetup.ps1" (
    echo ERRO: Create-WizardSetup.ps1 nao encontrado!
    echo.
    echo Certifique-se que o arquivo esta na mesma pasta.
    echo.
    pause
    exit /b 1
)

:: Perguntar nome do cliente (opcional)
echo Deseja personalizar o setup wizard para um cliente especifico?
echo (Pressione Enter para pular)
echo.
set /p CLIENT_NAME=Nome do Cliente:

echo.
echo Gerando setup wizard de licenciamento...
echo.

:: Executar o script PowerShell
if "%CLIENT_NAME%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-WizardSetup.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-WizardSetup.ps1" -ClientName "%CLIENT_NAME%"
)

:: Verificar resultado
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo Setup wizard criado com sucesso!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ERRO: Falha ao criar setup wizard
    echo ========================================
)

echo.
pause
