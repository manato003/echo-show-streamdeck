@echo off
REM Double-clickable launcher for restart_echoshow_kiosk.ps1.
REM All settings live in config.ps1 - nothing to edit here.
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0restart_echoshow_kiosk.ps1"
pause
