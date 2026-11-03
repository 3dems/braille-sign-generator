@echo off
cd /d "%~dp0"
echo ============================================================
echo   Empaquetando y Firmando Plugin: io.github.3dems.braille-sign-generator
echo ============================================================

set PS_EXE=D:\3D\PrusaSlicer\PrusaSlicer-3.0.0-alpha13\PrusaSlicer.exe
set PRIV_KEY=D:\3d\prusaslicer\keys\private_key.pem
set TARGET_DIR=%APPDATA%\PrusaSlicer3-dev\lua\io.github.3dems.braille-sign-generator

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

echo Copiando archivos a PrusaSlicer...
copy /Y "manifest.json" "%TARGET_DIR%\"
copy /Y "main.lua" "%TARGET_DIR%\"

if exist "%PRIV_KEY%" (
    echo Firmando plugin con la clave privada de desarrollador...
    "%PS_EXE%" plugin sign -f -P "%PRIV_KEY%" "%TARGET_DIR%"
)

echo.
echo ============================================================
echo   [OK] Plugin actualizado y firmado en PrusaSlicer con exito
echo ============================================================
echo.
pause
