@echo off
setlocal
cd /d "%~dp0"

net session >nul 2>&1
if not %errorlevel%==0 (
  echo Solicitando permissao de administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

where node >nul 2>&1 && goto :run
if exist "%ProgramFiles%\nodejs\node.exe" set "NODE=%ProgramFiles%\nodejs\node.exe" & goto :run

echo Node.js nao encontrado no PATH.
pause
exit /b 1

:run
if not defined NODE set "NODE=node"

if not exist "%~dp0node_modules\" (
  echo Execute npm install antes de criar o servico.
  pause
  exit /b 1
)

"%NODE%" "%~dp0scripts\servico-windows.js" install
if not %errorlevel%==0 (
  echo.
  echo Falha ao criar o servico.
  pause
  exit /b 1
)

echo.
pause
endlocal
