@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title ⚡ Llama.cpp Elite Launcher — RTX 5080 Blackwell
color 0A

:: Rutas Maestras
set "LLAMA_DIR=C:\data\llama-cpp-custom"
set "RESULT_FILE=%TEMP%\llama_launch.txt"
set "REAL_PORT=5050"
set "DISC_PORT=11434"

:START
cls
:: Limpieza de procesos
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im dns-sd.exe >nul 2>&1

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  ⚡  Llama.cpp Elite Launcher · RTX 5080 (Blackwell)    ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

if exist "%RESULT_FILE%" del "%RESULT_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launcher_gui.ps1"

if not exist "%RESULT_FILE%" (
    echo  ❌ Operación cancelada.
    timeout /t 2 >nul
    exit /b
)

:: Leer resultados con expansión retrasada
for /f "usebackq tokens=1-7 delims=|" %%A in ("%RESULT_FILE%") do (
    set "MODEL_PATH=%%A"
    set "VAL_CTX=%%B"
    set "VAL_NGL=%%C"
    set "VAL_NP=%%D"
    set "VAL_BATCH=%%E"
    set "HERMES_CFG=%%F"
    set "VAL_LAN=%%G"
)

:: Procesar IP dinámica
set "L_HOST=127.0.0.1"
set "L_IP=Localhost"
if "!VAL_LAN!"=="1" (
    for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | where {$_.IPAddress -like '192.*' -or $_.IPAddress -like '10.*' -or $_.IPAddress -like '172.*'} | select -ExpandProperty IPAddress -First 1"`) do set "CURRENT_IP=%%I"
    if NOT "!CURRENT_IP!"=="" (
        set "L_HOST=0.0.0.0"
        set "L_IP=!CURRENT_IP!"
        start "Blackwell-Shim" /min node "!LLAMA_DIR!\ollama_shim.js"
    )
)

:: Sincronizar Hermes
for %%F in ("!MODEL_PATH!") do set "MODEL_NAME=%%~nxF"
if exist "!HERMES_CFG!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!LLAMA_DIR!\sync_hermes.ps1" -ConfigPath "!HERMES_CFG!" -ModelName "!MODEL_NAME!" -Context "!VAL_CTX!"
)

:: Argumentos de Batch
set "B_ARGS="
if NOT "!VAL_BATCH!"=="Default" (set "B_ARGS=-ub !VAL_BATCH! -b !VAL_BATCH!")

:: Banner Final
cls
color 0A
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  🚀  BLACKWELL SERVER ACTIVO · RTX 5080 (Blackwell)      ║
echo  ║──────────────────────────────────────────────────────────║
echo  ║  Modelo   : !MODEL_NAME!
echo  ║  IP LAN   : !L_IP!
echo  ║  Puerto   : !REAL_PORT! (Discovery en !DISC_PORT!)
echo  ║──────────────────────────────────────────────────────────║
echo  ║  TIP: El iPhone ya deberia detectar el servidor.         ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

cd /d "!LLAMA_DIR!"
build\bin\llama-server.exe -m "!MODEL_PATH!" --flash-attn on -ngl !VAL_NGL! -c !VAL_CTX! -np !VAL_NP! -ctk q4_0 -ctv q4_0 !B_ARGS! --host !L_HOST! --port !REAL_PORT! --jinja

if %errorlevel% neq 0 (
    echo.
    echo [!] Error de motor Blackwell.
    pause
)
goto START
