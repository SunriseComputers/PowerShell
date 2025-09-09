@echo off
:: ==============================================
:: Dynamic GitHub-Based Setup Script
:: ==============================================

:: Step 0: Check for admin rights
>nul 2>&1 net session
if %errorLevel% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Set Execution Policy to Unrestricted
echo.
echo Setting Execution Policy to Unrestricted...
powershell -Command "Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force"
color 0A

:: ASCII Art Header
echo.
echo   _____                             ____                            _                
echo  / ____^|                           ^/ ____^|                          ^| ^|               
echo ^| (___  _   _ _ __ ___ _ __   _     ^| ^|     ___  _ __ ___  _ __  _   _^| ^|_ ___ _ __ ___ 
echo  \\___ \\^| ^| ^| ^| '_ ` _ \\^| '_ \\ ^(_^)   ^| ^|    / _ \\^| '_ ` _ \\^| '_ \\^| ^| ^| ^| __/ _ \\^| '__/ __^|
echo  ____) ^| ^|_^| ^| ^| ^| ^| ^| ^| ^|_) ^|_     ^| ^|___^| (_) ^| ^| ^| ^| ^| ^| ^|_) ^| ^|_^| ^| ^|^|  __/^| ^|  \\__ \\
echo ^|_____/ \\__,_^|_^| ^|_^| ^|_^| .__/^(_^)     \\_____\\___/^|_^| ^|_^| ^|_^| .__/ \\__,_^|\\__\\___|^|_^|  ^|___/
echo                        ^| ^|                                ^| ^|                           
echo                        ^|_^|                                ^|_^|                          
echo.
echo Performance Computing - Since 2001 
echo.

:: GitHub Configuration - UPDATE THIS TO YOUR REPOSITORY
set "GITHUB_BASE=https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/Scripts"

:: Script Configuration - Define your script mappings
set "script_winget=Winget_Install.ps1"
set "script_online_apps=Online-app-Install.ps1" 
set "script_offline_apps=Offline-app_Install.ps1"
set "script_tweaks=Performance_Tweaks.ps1"
set "script_bloatware=App_Remover.ps1"

:MENU
echo ==================================================
echo             WINDOWS AUTO SETUP TOOLKIT
echo                  (Dynamic GitHub Edition)
echo ==================================================
echo [1] Install WinGet
echo [2] Install Apps (Online)
echo [3] Install Apps (Offline) 
echo [4] Apply Performance Tweaks
echo [5] Remove Bloatware
echo [6] Run Everything
echo [7] List Available Scripts
echo [8] Run Custom Script
echo [0] Exit
echo ==================================================
set /p choice="Choose an option: "

if "%choice%"=="1" call :run_script "%script_winget%" "WinGet Installer"
if "%choice%"=="2" call :run_script "%script_online_apps%" "Online App Installer"
if "%choice%"=="3" call :run_script "%script_offline_apps%" "Offline App Installer"
if "%choice%"=="4" call :run_script "%script_tweaks%" "Performance Tweaks"
if "%choice%"=="5" call :run_script "%script_bloatware%" "Bloatware Remover"
if "%choice%"=="6" goto run_all
if "%choice%"=="7" goto list_scripts
if "%choice%"=="8" goto run_custom
if "%choice%"=="0" goto cleanup_exit
goto MENU

:: Function to run a single script
:run_script
set "script_name=%~1"
set "display_name=%~2"
echo.
echo Downloading and running %display_name% from GitHub...
echo Script: %script_name%
echo URL: %GITHUB_BASE%/%script_name%
echo.
powershell -Command "try { Write-Host 'Fetching %script_name%...' -ForegroundColor Cyan; $script = irm '%GITHUB_BASE%/%script_name%'; if ($script) { iex $script } else { throw 'Empty script received' } } catch { Write-Host 'Error: Could not download or run %script_name%' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Yellow; pause }"
pause
goto MENU

:list_scripts
echo.
echo Checking available scripts on GitHub...
echo.
powershell -Command "try { Write-Host 'Available Scripts:' -ForegroundColor Green; Write-Host '==================' -ForegroundColor Green; $api_url = '%GITHUB_BASE%'.Replace('/raw.githubusercontent.com/', '/api.github.com/repos/').Replace('/main/Scripts', '/contents/Scripts'); $scripts = irm $api_url; foreach ($script in $scripts) { if ($script.name -like '*.ps1') { Write-Host \"  - $($script.name)\" -ForegroundColor White } } } catch { Write-Host 'Could not fetch script list from GitHub' -ForegroundColor Red; Write-Host 'Manual script list:' -ForegroundColor Yellow; Write-Host '  - %script_winget%'; Write-Host '  - %script_online_apps%'; Write-Host '  - %script_offline_apps%'; Write-Host '  - %script_tweaks%'; Write-Host '  - %script_bloatware%' }"
echo.
pause
goto MENU

:run_custom
echo.
echo Available scripts:
echo - %script_winget%
echo - %script_online_apps%
echo - %script_offline_apps%
echo - %script_tweaks%
echo - %script_bloatware%
echo.
set /p custom_script="Enter script filename (e.g., Custom_Script.ps1): "
if "%custom_script%"=="" goto MENU
call :run_script "%custom_script%" "Custom Script"
goto MENU

:run_all
echo.
echo Running all setup tasks from GitHub...
echo WARNING: This will download and run all scripts automatically.
echo.
set /p confirm="Are you sure you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU

echo.
call :run_script_silent "%script_winget%" "WinGet Installer" "1/5"
call :run_script_silent "%script_online_apps%" "Online App Installer" "2/5"
call :run_script_silent "%script_offline_apps%" "Offline App Installer" "3/5"
call :run_script_silent "%script_tweaks%" "Performance Tweaks" "4/5"
call :run_script_silent "%script_bloatware%" "Bloatware Remover" "5/5"

echo.
echo ========================================
echo All tasks completed!
echo ========================================
pause
goto MENU

:: Function to run script silently (for batch operations)
:run_script_silent
set "script_name=%~1"
set "display_name=%~2"
set "progress=%~3"
echo.
echo [%progress%] Running %display_name%...
powershell -Command "try { Write-Host 'Fetching %script_name%...' -ForegroundColor Cyan; $script = irm '%GITHUB_BASE%/%script_name%'; if ($script) { iex $script } else { throw 'Empty script received' } } catch { Write-Host 'Failed to run %display_name%: ' $_.Exception.Message -ForegroundColor Red }"
goto :eof

:cleanup_exit
echo.
echo Resetting Execution Policy to Restricted...
powershell -Command "Set-ExecutionPolicy Restricted -Scope LocalMachine -Force" >nul 2>&1

echo.
echo Thank you for using Windows Auto Setup Toolkit!
echo Exiting in 3 seconds...
timeout /t 3 >nul
exit /b
