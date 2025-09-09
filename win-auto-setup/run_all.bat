@echo off
:: ===========================================
:: Master Setup Batch Script with Admin Check
:: ===========================================

:: Step 0: Check for admin rights
>nul 2>&1 net session
if %errorLevel% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ============
:: Setup Paths
:: ============
setlocal
set "BaseFolder=%~dp0"

set "ScriptPath=%BaseFolder%Scripts"
set "FilesPath=%BaseFolder%Files"

:: =============================================
:: Step 1: Set Execution Policy to Unrestricted
:: =============================================
echo.
echo Setting Execution Policy to Unrestricted...
powershell -Command "Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force"

:: =======================
:: Step 2: Install Winget
:: =======================
echo.
echo Installing Winget...
powershell -ExecutionPolicy Bypass -File "%ScriptPath%\Winget_Install.ps1"

:: ==============================================
:: Step 3: Ask for Online or Offline App Install
:: ==============================================
echo.
set /p appMode=Do you want to install apps ONLINE or OFFLINE? (Type 1 - ONLINE/ 2 - OFFLINE or press Enter to skip): 

if /I "%appMode%"=="1" (
    echo Running online app installation script...
    powershell -ExecutionPolicy Bypass -File "%ScriptPath%\install_apps_online.ps1"
) else if /I "%appMode%"=="2" (
    echo Running offline app installation script...
    powershell -ExecutionPolicy Bypass -File "%ScriptPath%\install_apps_offline.ps1"
) else (
    echo Skipping App Installation.
)

:: =========================================
:: Step 4: Apply Tweaks for Best Perfomance
:: =========================================
echo.
set /p runBloat=Do you want to Apply Settings for Best Perfomance (RECOMMED)? (Y/N): 
if /I "%runBloat%"=="Y" (
    echo Running tweaks script...
    powershell -ExecutionPolicy Bypass -File "%ScriptPath%\Perfomance_Tweaks.ps1"
) else (
    echo Skipping - NO Perfomance Changes Applied.
)


:: ======================================================
:: Step 5: Stop Windows Auto Update Delay WIndows Update.
:: ======================================================
echo.
echo Running bloatware remover script...
powershell -ExecutionPolicy Bypass -File "%ScriptPath%\Delay-WindowsUpdates.ps1"


:: ========================================
:: Step 6: Bloatware App Remover (Optional)
:: ========================================
echo.
set /p runBloat=Do you want to run the Bloatware App Remover? (Y/N): 
if /I "%runBloat%"=="Y" (
    echo Running bloatware remover script...
    powershell -ExecutionPolicy Bypass -File "%ScriptPath%\Bloatware_App_Remover.ps1"
) else (
    echo Skipping Bloatware Remover.
)

:: ===============================
:: Step 6: Reset Execution Policy
:: ===============================
echo.
echo Resetting Execution Policy to Restricted...
powershell -Command "Set-ExecutionPolicy Restricted -Scope LocalMachine -Force"

:: ========================================
:: Step 7: Close All CMD/PowerShell Windows
:: ========================================
echo.
echo All selected tasks completed.
echo This window will now close.
timeout /t 3 >nul

:: Force close all PowerShell and CMD windows (including this one)
taskkill /f /im powershell.exe >nul 2>&1
taskkill /f /im cmd.exe >nul 2>&1
exit
