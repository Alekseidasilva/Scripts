@echo off
:: ====================================================================
:: Consultar Licencas PRIMAVERA
:: Visualizar licencas ativas e historico
:: ====================================================================

:: Mudar para o diretorio onde o script esta localizado
cd /d "%~dp0"

echo ========================================
echo CONSULTAR LICENCAS PRIMAVERA
echo ========================================
echo.

:: Verificar se o arquivo PowerShell existe
if not exist "View-Licenses.ps1" (
    echo ERRO: View-Licenses.ps1 nao encontrado!
    echo.
    echo Certifique-se que o arquivo esta na mesma pasta.
    echo.
    pause
    exit /b 1
)

:: Executar o script PowerShell
echo Carregando licencas...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0View-Licenses.ps1"

echo.
pause
