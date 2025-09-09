# ==============================================
# Dynamic GitHub-Based Setup Script
# ==============================================

#Requires -RunAsAdministrator

# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`""
    exit
}

# Set Execution Policy
try {
    Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force
    Write-Host "Execution Policy set successfully." -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not set execution policy: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Set console colors
try {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
} catch {
    # Ignore color setting errors
}

# ASCII Art Header
Write-Host ""
Write-Host "  _____                             ____                            _                " -ForegroundColor Cyan
Write-Host " / ____|                           / ____|                          | |               " -ForegroundColor Cyan
Write-Host "| (___  _   _ _ __ ___ _ __   _     | |     ___  _ __ ___  _ __  _   _| |_ ___ _ __ ___ " -ForegroundColor Cyan
Write-Host " \___ \| | | | '_ ` _ \| '_ \ (_)   | |    / _ \| '_ ` _ \| '_ \| | | | __/ _ \| '__/ __|" -ForegroundColor Cyan
Write-Host " ____) | |_| | | | | | | |_) |_    | |___| (_) | | | | | | |_) | |_| | ||  __/| |  \__ \" -ForegroundColor Cyan
Write-Host "|_____/ \__,_|_| |_| |_| .__/(_)    \_____\___/|_| |_| |_| .__/ \__,_|\__\___||_|  |___/" -ForegroundColor Cyan
Write-Host "                      | |                               | |                           " -ForegroundColor Cyan
Write-Host "                      |_|                               |_|                          " -ForegroundColor Cyan
Write-Host ""
Write-Host "Performance Computing" -ForegroundColor Yellow
Write-Host "Since 2001" -ForegroundColor Yellow
Write-Host ""

# Configuration
$GITHUB_BASE = "https://raw.githubusercontent.com/SunriseComputers/PowerShell/main/win-auto-setup/Scripts"
$scripts = @{
    winget = "Winget_Install.ps1"
    online_apps = "Online-app-Install.ps1"
    offline_apps = "Offline-app_Install.ps1"
    tweaks = "Performance_Tweaks.ps1"
    bloatware = "App_Remover.ps1"
}

# Helper function for pausing
function Wait-ForKey {
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to run script from GitHub
function Invoke-GitHubScript {
    param(
        [string]$ScriptName,
        [string]$DisplayName,
        [switch]$Silent
    )
    
    if (-not $Silent) {
        Write-Host "`nDownloading and running $DisplayName..." -ForegroundColor Green
    } else {
        Write-Host "Running $DisplayName..." -ForegroundColor Green
    }
    
    try {
        $script = Invoke-RestMethod -Uri "$GITHUB_BASE/$ScriptName"
        if ($script) {
            Invoke-Expression $script
        } else {
            throw "Empty script received"
        }
    } catch {
        Write-Host "Error: Could not download or run $ScriptName" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
    
    if (-not $Silent) {
        Wait-ForKey
    }
}

# Function to display menu
function Show-Menu {
    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "             WINDOWS AUTO SETUP TOOLKIT" -ForegroundColor White
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "[1] Install WinGet" -ForegroundColor White
    Write-Host "[2] Install Apps (Online)" -ForegroundColor White
    Write-Host "[3] Install Apps (Offline)" -ForegroundColor White
    Write-Host "[4] Apply Performance Tweaks" -ForegroundColor White
    Write-Host "[5] Remove Bloatware" -ForegroundColor White
    Write-Host "[6] Run Everything" -ForegroundColor Yellow
    Write-Host "[7] List Available Scripts" -ForegroundColor White
    Write-Host "[8] Run Custom Script" -ForegroundColor White
    Write-Host "[0] Exit" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Cyan
    Read-Host "Choose an option"
}

# Function to list available scripts
function Show-AvailableScripts {
    Write-Host "`nAvailable Scripts:" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    $scripts.Values | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    Wait-ForKey
}

# Function to run custom script
function Invoke-CustomScript {
    Show-AvailableScripts
    $custom_script = Read-Host "`nEnter script filename"
    if (-not [string]::IsNullOrWhiteSpace($custom_script)) {
        Invoke-GitHubScript -ScriptName $custom_script -DisplayName "Custom Script"
    }
}

# Function to run all scripts
function Invoke-AllScripts {
    Write-Host "`nWARNING: This will download and run all scripts automatically." -ForegroundColor Red
    $confirm = Read-Host "Are you sure you want to continue? (Y/N)"
    
    if ($confirm -eq "Y" -or $confirm -eq "y") {
        $i = 1
        $total = $scripts.Count
        $scripts.GetEnumerator() | ForEach-Object {
            Write-Host "`n[$i/$total] " -NoNewline -ForegroundColor Yellow
            Invoke-GitHubScript -ScriptName $_.Value -DisplayName $_.Key -Silent
            $i++
        }
        Write-Host "`nAll tasks completed!" -ForegroundColor Green
        Wait-ForKey
    }
}

# Main script loop
try {
    do {
        $choice = Show-Menu
        
        switch ($choice) {
            "1" { Invoke-GitHubScript -ScriptName $scripts.winget -DisplayName "WinGet Installer" }
            "2" { Invoke-GitHubScript -ScriptName $scripts.online_apps -DisplayName "Online App Installer" }
            "3" { Invoke-GitHubScript -ScriptName $scripts.offline_apps -DisplayName "Offline App Installer" }
            "4" { Invoke-GitHubScript -ScriptName $scripts.tweaks -DisplayName "Performance Tweaks" }
            "5" { Invoke-GitHubScript -ScriptName $scripts.bloatware -DisplayName "Bloatware Remover" }
            "6" { Invoke-AllScripts }
            "7" { Show-AvailableScripts }
            "8" { Invoke-CustomScript }
            "0" { 
                Write-Host "`nResetting Execution Policy..." -ForegroundColor Yellow
                try { Set-ExecutionPolicy Restricted -Scope LocalMachine -Force } catch {}
                Write-Host "Thank you for using Windows Auto Setup Toolkit!" -ForegroundColor Green
                Start-Sleep -Seconds 2
                exit
            }
            default { 
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
} catch {
    Write-Host "`nAn unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Wait-ForKey
    exit 1
}
