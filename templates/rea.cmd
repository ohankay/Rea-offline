@echo off
rem REA offline launcher: uses the Node.js (and optional Ghidra/JDK) in this bundle.
setlocal
set "ROOT=%~dp0.."
if exist "%ROOT%\ghidra" if not defined GHIDRA_INSTALL_DIR set "GHIDRA_INSTALL_DIR=%ROOT%\ghidra"
if exist "%ROOT%\jdk" if not defined JAVA_HOME set "JAVA_HOME=%ROOT%\jdk"
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"
set "PATH=%ROOT%\node;%PATH%"
set "NO_UPDATE_NOTIFIER=1"
"%ROOT%\node\node.exe" "%ROOT%\app\node_modules\rea-agents\scripts\rea.mjs" %*
