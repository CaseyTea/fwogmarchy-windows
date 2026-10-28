@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" %*
if errorlevel 1 (
  echo Setup failed. Read the error above before retrying.
  pause
  exit /b 1
)
pause
