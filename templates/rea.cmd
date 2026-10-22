@echo off
rem REA offline launcher: uses the Node.js (and optional Ghidra/JDK) in this bundle.
setlocal
set "ROOT=%~dp0.."
if not defined REA_USE_SYSTEM_TOOLS if exist "%ROOT%\ghidra" set "GHIDRA_INSTALL_DIR=%ROOT%\ghidra"
if not defined REA_USE_SYSTEM_TOOLS if exist "%ROOT%\jdk" set "JAVA_HOME=%ROOT%\jdk"
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"
set "PATH=%ROOT%\node;%PATH%"
set "NO_UPDATE_NOTIFIER=1"
"%ROOT%\node\node.exe" "%ROOT%\app\node_modules\rea-agents\scripts\rea.mjs" %*
