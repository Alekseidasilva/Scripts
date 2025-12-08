@echo off
:: ====================================================================
:: Desinstalador de Tarefa Agendada PRIMAVERA
:: Remove todas as tarefas e arquivos de log/estado
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
    echo 1. Clique com botao direito em DESINSTALAR.bat
    echo 2. Selecione "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

echo ========================================
echo Desinstalador PRIMAVERA
echo ========================================
echo.
echo Este script ira:
echo - Remover a tarefa agendada anual
echo - Remover qualquer tarefa de retry pendente
echo - Opcionalmente deletar logs e arquivos de estado
echo.

choice /C SN /M "Deseja continuar"
if errorlevel 2 (
    echo Desinstalacao cancelada pelo usuario.
    pause
    exit /b 0
)

echo.
echo Removendo tarefas agendadas...

:: Remover tarefa anual
schtasks /Delete /TN "PRIMAVERA_Annual_Cleanup" /F >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Tarefa anual removida: PRIMAVERA_Annual_Cleanup
) else (
    echo [INFO] Tarefa anual nao encontrada: PRIMAVERA_Annual_Cleanup
)

:: Remover tarefa de retry
schtasks /Delete /TN "PRIMAVERA_Cleanup_Retry" /F >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Tarefa de retry removida: PRIMAVERA_Cleanup_Retry
) else (
    echo [INFO] Tarefa de retry nao encontrada: PRIMAVERA_Cleanup_Retry
)

echo.
echo ========================================
echo Tarefas agendadas removidas!
echo ========================================
echo.

:: Perguntar sobre deletar logs
choice /C SN /M "Deseja deletar logs e arquivos de estado"
if errorlevel 2 (
    echo Logs mantidos em: C:\ProgramData\PrimaveraCleanup
    goto :fim
)

echo.
echo Removendo logs e arquivos de estado...

:: Deletar diretório de logs
if exist "C:\ProgramData\PrimaveraCleanup" (
    rd /S /Q "C:\ProgramData\PrimaveraCleanup" >nul 2>&1
    if %errorLevel% == 0 (
        echo [OK] Logs e estado deletados
    ) else (
        echo [AVISO] Nao foi possivel deletar alguns arquivos
        echo Tente deletar manualmente: C:\ProgramData\PrimaveraCleanup
    )
) else (
    echo [INFO] Nenhum log encontrado
)

:fim
echo.
echo ========================================
echo Desinstalacao concluida!
echo ========================================
echo.
echo Os scripts de instalacao continuam disponiveis
echo e podem ser executados novamente a qualquer momento.
echo.
pause
