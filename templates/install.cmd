@echo off
rem Double-click or run from cmd: installs REA offline for the current user.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause
