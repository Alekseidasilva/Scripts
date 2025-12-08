@echo off
:: ====================================================================
:: Renovar Licenca PRIMAVERA
:: Estender periodo de licenca existente
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
    echo 1. Clique com botao direito em RENOVAR-LICENCA.bat
    echo 2. Selecione "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

:: Mudar para o diretorio onde o script esta localizado
cd /d "%~dp0"

echo ========================================
echo RENOVAR LICENCA PRIMAVERA
echo ========================================
echo.

:: Verificar se o arquivo PowerShell existe
if not exist "Renew-License.ps1" (
    echo ERRO: Renew-License.ps1 nao encontrado!
    echo.
    echo Certifique-se que o arquivo esta na mesma pasta.
    echo.
    pause
    exit /b 1
)

:: Executar o script PowerShell
echo Iniciando processo de renovacao...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Renew-License.ps1"

:: Verificar resultado
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo Processo concluido
    echo ========================================
) else (
    echo.
    echo ========================================
    echo AVISO: Processo finalizado com avisos
    echo ========================================
)

echo.
pause
