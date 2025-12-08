@echo off
:: ====================================================================
:: Gerador de Executavel (.EXE) - Wizard de Licenciamento PRIMAVERA
:: Cria um arquivo .exe profissional com interface wizard
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
    echo 1. Clique com botao direito em CRIAR-EXE-WIZARD.bat
    echo 2. Selecione "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

:: Mudar para o diretorio onde o script esta localizado
cd /d "%~dp0"

echo ========================================
echo GERADOR DE EXECUTAVEL (.EXE) - WIZARD
echo ========================================
echo.

:: Verificar se o arquivo PowerShell existe
if not exist "Create-ExecutableSetup.ps1" (
    echo ERRO: Create-ExecutableSetup.ps1 nao encontrado!
    echo.
    echo Certifique-se que o arquivo esta na mesma pasta.
    echo.
    pause
    exit /b 1
)

:: Perguntar nome do cliente (opcional)
echo Deseja personalizar o executavel para um cliente especifico?
echo (Pressione Enter para pular)
echo.
set /p CLIENT_NAME=Nome do Cliente:

:: Perguntar nome do arquivo de saida (opcional)
echo.
echo Nome do arquivo .exe a ser criado?
echo (Pressione Enter para usar o padrao: SETUP-PRIMAVERA-WIZARD.exe)
echo.
set /p OUTPUT_NAME=Nome do arquivo:

if "%OUTPUT_NAME%"=="" (
    set OUTPUT_NAME=SETUP-PRIMAVERA-WIZARD.exe
)

echo.
echo Gerando executavel (.exe) com interface WIZARD...
echo.
echo Este processo pode levar alguns segundos...
echo.

:: Executar o script PowerShell
if "%CLIENT_NAME%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-ExecutableSetup.ps1" -InterfaceType Wizard -OutputPath "%OUTPUT_NAME%"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-ExecutableSetup.ps1" -InterfaceType Wizard -OutputPath "%OUTPUT_NAME%" -ClientName "%CLIENT_NAME%"
)

:: Verificar resultado
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo Executavel criado com sucesso!
    echo ========================================
    echo.
    echo Arquivo: %OUTPUT_NAME%
    echo.
    echo O arquivo .exe esta pronto para ser distribuido!
    echo.
) else (
    echo.
    echo ========================================
    echo ERRO: Falha ao criar executavel
    echo ========================================
)

echo.
pause
