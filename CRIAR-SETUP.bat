@echo off
:: ====================================================================
:: Gerador de Setup de Licenciamento PRIMAVERA
:: Cria um pacote autocontido com todos os arquivos necessarios
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
    echo 1. Clique com botao direito em CRIAR-SETUP.bat
    echo 2. Selecione "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

:: Mudar para o diretorio onde o script esta localizado
cd /d "%~dp0"

echo ========================================
echo GERADOR DE SETUP DE LICENCIAMENTO
echo ========================================
echo.

:: Verificar se o arquivo PowerShell existe
if not exist "Create-LicenseSetup.ps1" (
    echo ERRO: Create-LicenseSetup.ps1 nao encontrado!
    echo.
    echo Certifique-se que o arquivo esta na mesma pasta.
    echo.
    pause
    exit /b 1
)

:: Perguntar nome do cliente (opcional)
echo Deseja personalizar o setup para um cliente especifico?
echo (Pressione Enter para pular)
echo.
set /p CLIENT_NAME=Nome do Cliente:

echo.
echo Gerando setup de licenciamento...
echo.

:: Executar o script PowerShell
if "%CLIENT_NAME%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-LicenseSetup.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-LicenseSetup.ps1" -ClientName "%CLIENT_NAME%"
)

:: Verificar resultado
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo Setup criado com sucesso!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ERRO: Falha ao criar setup
    echo ========================================
)

echo.
pause
