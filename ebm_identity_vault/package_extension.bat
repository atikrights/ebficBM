@echo off
set VERSION=1.0.0
set FILENAME=ebm_identity_vault_v%VERSION%.zip

echo [1/3] Cleaning old builds...
if exist %FILENAME% del %FILENAME%

echo [2/3] Packaging extension files...
powershell -Command "Compress-Archive -Path manifest.json, popup.html, popup.js, background.js, content.js, icons -DestinationPath %FILENAME%"

echo [3/3] Done! Created: %FILENAME%
echo.
echo Pro Tip: You can now share %FILENAME% with your team or upload it to the Chrome Web Store.
pause