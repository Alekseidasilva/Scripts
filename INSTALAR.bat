@echo off
:: ====================================================================
:: Instalador de Tarefa Agendada PRIMAVERA
:: Execute este arquivo com duplo clique ou clique direito > Executar como Administrador
:: ====================================================================

:: Verificar se está executando como Administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Executando com privilegios de Administrador...
    echo.
) else (
    echo.
    echo ========================================
    echo ERRO: Privilégios de Administrador necessários!
    echo ========================================
    echo.
    echo Este script precisa ser executado como Administrador.
    echo.
    echo Por favor:
    echo 1. Clique com botao direito em INSTALAR.bat
    echo 2. Selecione "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

:: Mudar para o diretório onde o script está localizado
cd /d "%~dp0"

echo ========================================
echo Instalador PRIMAVERA - Iniciando...
echo ========================================
echo.

:: Verificar se o arquivo PowerShell existe
if not exist "Install-PrimaveraCleanupTask.ps1" (
    echo ERRO: Install-PrimaveraCleanupTask.ps1 nao encontrado!
    echo.
    echo Certifique-se que todos os arquivos estao na mesma pasta:
    echo - INSTALAR.bat
    echo - Install-PrimaveraCleanupTask.ps1
    echo - Delete-PrimaveraFiles.ps1
    echo.
    pause
    exit /b 1
)

:: Executar o script PowerShell
echo Executando instalacao...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-PrimaveraCleanupTask.ps1"

:: Verificar resultado
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo Instalacao concluida!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ERRO: Falha na instalacao
    echo ========================================
)

echo.
pause
