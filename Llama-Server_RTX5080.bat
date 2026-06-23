@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title ⚡ Llama.cpp Elite Launcher — RTX 5080 Blackwell
color 0A

:: Eliminar el trailing slash de %~dp0
set "LLAMA_DIR=%~dp0"
if "%LLAMA_DIR:~-1%"=="\" set "LLAMA_DIR=%LLAMA_DIR:~0,-1%"
set "RESULT_FILE=%TEMP%\llama_launch.txt"

:START
cls
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  ⚡  Llama.cpp Elite Launcher · RTX 5080 (Blackwell)    ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  Abriendo Centro de Control...
echo.

:: Limpiar resultado previo
if exist "%RESULT_FILE%" del "%RESULT_FILE%"

:: Abrir GUI unificada
powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launcher_gui.ps1"

:: Si no hay resultado, el usuario cerró la ventana
if not exist "%RESULT_FILE%" (
    echo  ❌ Operación cancelada.
    timeout /t 2 >nul
    exit /b
)

:: Leer resultados del GUI
for /f "usebackq tokens=1-6 delims=|" %%A in ("%RESULT_FILE%") do (
    set "MODEL_PATH=%%A"
    set "VAL_CTX=%%B"
    set "VAL_NGL=%%C"
    set "VAL_NP=%%D"
    set "VAL_BATCH=%%E"
    set "HERMES_CFG=%%F"
)

:: Sincronizar con Hermes config.yaml
for %%F in ("%MODEL_PATH%") do set "MODEL_NAME=%%~nxF"

if exist "%HERMES_CFG%" (
    echo  🔄 Sincronizando %MODEL_NAME% con Hermes...
    powershell -NoProfile -Command "(Get-Content '%HERMES_CFG%') -replace '^model:\s*$', 'model:' -replace '^\s*default:.*', '  default: %MODEL_NAME%' -replace '^\s*context_length:.*', '  context_length: %VAL_CTX%' | Set-Content '%HERMES_CFG%'"
) else (
    echo  ⚠️ Salto de sincronización: Hermes config no encontrado en %HERMES_CFG%
)

:: Construir args de batch
set "BATCH_ARGS="
if NOT "%VAL_BATCH%"=="Default" (
    set "BATCH_ARGS=-ub %VAL_BATCH% -b %VAL_BATCH%"
)

:: Nombre para banner
for %%F in ("%MODEL_PATH%") do set "MODEL_NAME=%%~nxF"

:: Lanzar servidor con estética verde
cls
color 0A
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  🚀  LLAMA-SERVER ACTIVO · RTX 5080 (Blackwell)        ║
echo  ║──────────────────────────────────────────────────────────║
echo  ║  Modelo  : %MODEL_NAME%
echo  ║  GPU     : sm_120a nativo                                ║
echo  ║  Contexto: %VAL_CTX% tokens
echo  ║  Layers  : %VAL_NGL% ^| Slots: %VAL_NP% ^| KV: Q4_0
echo  ║  Puerto  : 5050                                          ║
echo  ║  API     : http://127.0.0.1:5050/v1                      ║
echo  ║  FA      : ON                                            ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  [Ctrl+C] para detener el servidor
echo  ────────────────────────────────────────────────────────────
echo.

cd /d "%LLAMA_DIR%"

build\bin\llama-server.exe ^
  -m "%MODEL_PATH%" ^
  --flash-attn on ^
  -ngl %VAL_NGL% ^
  -c %VAL_CTX% ^
  -np %VAL_NP% ^
  -ctk q4_0 ^
  -ctv q4_0 ^
  %BATCH_ARGS% ^
  --host 0.0.0.0 ^
  --port 5050 ^
  --jinja

echo.
echo  ────────────────────────────────────────────────────────────
echo  Servidor detenido. Volviendo al selector en 3s...
timeout /t 3
goto START
