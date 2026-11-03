@echo off
cd /d "%~dp0"
echo ============================================================
echo   Empaquetando Plugin: io.github.3dems.braille-sign-generator
echo ============================================================

set OUT_ZIP=%~dp0io.github.3dems.braille-sign-generator.zip

if exist "%OUT_ZIP%" del "%OUT_ZIP%"

powershell -Command "Compress-Archive -Path 'manifest.json', 'main.lua', 'README.md' -DestinationPath '%OUT_ZIP%'"

echo [OK] Paquete generado con exito en:
echo %OUT_ZIP%
echo.
pause
