@echo off
setlocal
cd /d "%~dp0"

set "HOST=127.0.0.1"
set "PORT=8787"

if not defined WARZONE_STATE_FILE (
  for %%D in (DCS.openbeta_server DCS.server DCS.openbeta DCS) do (
    if exist "%USERPROFILE%\Saved Games\%%D\WarZoneWeb\WarZoneWebState.json" (
      set "WARZONE_STATE_FILE=%USERPROFILE%\Saved Games\%%D\WarZoneWeb\WarZoneWebState.json"
      goto :state_found
    )
  )
)

:state_found
if not defined WARZONE_STATE_FILE set "WARZONE_STATE_FILE=%USERPROFILE%\Saved Games\DCS\WarZoneWeb\WarZoneWebState.json"

where node >nul 2>nul
if errorlevel 1 (
  echo [WarZone Web] Node.js non trovato.
  echo Installa Node.js 20+ e riapri questo file.
  pause
  exit /b 1
)

echo [WarZone Web] Avvio Command Center...
echo [WarZone Web] Telemetria: %WARZONE_STATE_FILE%
echo [WarZone Web] URL locale: http://127.0.0.1:%PORT%
echo.

node server.js

echo.
echo [WarZone Web] Il server si e' arrestato.
pause
