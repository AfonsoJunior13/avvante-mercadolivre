@echo off
setlocal

set "LOG_DIR=%~dp0logs"

if not exist "%LOG_DIR%" (
  echo Pasta logs nao encontrada: %LOG_DIR%
  exit /b 1
)

echo Limpando logs em: %LOG_DIR%
del /s /q "%LOG_DIR%\*.*" >nul 2>&1

echo Logs apagados.
endlocal
