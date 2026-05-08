@echo off
setlocal enabledelayedexpansion
title 🚀 EBM Control Deployer

:: --- Configuration ---
set REMOTE_HOST=37.44.245.178
set REMOTE_USER=u200841033
set REMOTE_PORT=65002
set REMOTE_PATH=/home/u200841033/domains/ebfic.store/public_html/com/

:: Setting Colors (Green on Black)
color 0A

echo.
echo  ##########################################################
echo  #                                                        #
echo  #      EBM CONTROL (SUPER ADMIN) LIVE DEPLOYER           #
echo  #                                                        #
echo  ##########################################################
echo.
echo  [SYSTEM] Initializing deployment process...
echo.

:: 1. Build Flutter Web
echo  [1/3] 🛠️  BUILDING: Creating Flutter Web Release...
echo  ----------------------------------------------------------
call flutter build web --release --no-wasm-dry-run
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo  ❌ ERROR: Build failed! Check your code and try again.
    pause
    exit /b %errorlevel%
)
echo.
echo  ✅ DONE: Build complete.
echo.

:: 2. Deploy to Server
echo  [2/3] 📤  UPLOADING: Sending files to Hostinger...
echo  ----------------------------------------------------------

:: Advanced rsync detection
set RSYNC_PATH=rsync
where rsync >nul 2>nul
if %errorlevel% neq 0 (
    if exist "C:\Program Files\Git\usr\bin\rsync.exe" (
        set RSYNC_PATH="C:\Program Files\Git\usr\bin\rsync.exe"
    ) else if exist "C:\Program Files (x86)\Git\usr\bin\rsync.exe" (
        set RSYNC_PATH="C:\Program Files (x86)\Git\usr\bin\rsync.exe"
    ) else (
        echo  ⚠️  rsync not found. Trying to use Windows SCP instead...
        :: Fallback to SCP if rsync is missing (Note: scp is less efficient but works on all Windows 10+)
        scp -P %REMOTE_PORT% -r build/web/* %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_PATH%
        goto scp_check
    )
)

%RSYNC_PATH% -avz --progress --delete --exclude ".env" -e "ssh -p %REMOTE_PORT% -o StrictHostKeyChecking=no" build/web/ %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_PATH%

:scp_check
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo  ❌ ERROR: Deployment failed! Check your SSH connection.
    echo  TIP: Make sure you can SSH into your server manually first.
    pause
    exit /b %errorlevel%
)
echo.
echo  ✅ DONE: Files uploaded to server.
echo.

:: 3. Backup to GitHub
echo  [3/3] 💾  BACKUP: Securing code on GitHub...
echo  ----------------------------------------------------------
git add .
git commit -m "Auto-deploy backup: %date% %time%"
git push

if %errorlevel% neq 0 (
    echo  ⚠️  WARNING: GitHub push failed, but server is OK.
) else (
    echo  ✅ DONE: GitHub backup successful.
)

echo.
echo  ==========================================================
echo  🎊 SUCCESS: EBM Control is now LIVE and SECURED!
echo  ==========================================================
echo.
echo  Press any key to close this dashboard...
pause > nul
