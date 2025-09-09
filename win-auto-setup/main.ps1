# ==============================================
# Dynamic GitHub-Based Setup Script
# ==============================================

# Requires -RunAsAdministrator

# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`""
    exit
}

# Set Execution Policy to Unrestricted
Write-Host ""
Write-Host "Setting Execution Policy to Unrestricted..." -ForegroundColor Green
Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force

# Set console colors
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

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
Write-Host "Performance Computing - Since 2001" -ForegroundColor Yellow
Write-Host ""

# GitHub Configuration - UPDATE THIS TO YOUR REPOSITORY
$GITHUB_BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/Scripts"

# Script Configuration - Define your script mappings
$script_winget = "Winget_Install.ps1"
$script_online_apps = "Online-app-Install.ps1"
$script_offline_apps = "Offline-app_Install.ps1"
$script_tweaks = "Performance_Tweaks.ps1"
$script_bloatware = "App_Remover.ps1"

# Function to display menu and get user choice
function Show-Menu {
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "             WINDOWS AUTO SETUP TOOLKIT" -ForegroundColor White
    Write-Host "                  (Dynamic GitHub Edition)" -ForegroundColor Gray
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
    $choice = Read-Host "Choose an option"
    return $choice
}

# Function to run a single script
function Invoke-ScriptFromGitHub {
    param(
        [string]$ScriptName,
        [string]$DisplayName
    )
    
    Write-Host ""
    Write-Host "Downloading and running $DisplayName from GitHub..." -ForegroundColor Green
    Write-Host "Script: $ScriptName" -ForegroundColor Gray
    Write-Host "URL: $GITHUB_BASE/$ScriptName" -ForegroundColor Gray
    Write-Host ""
    
    try {
        Write-Host "Fetching $ScriptName..." -ForegroundColor Cyan
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
    
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to run script silently (for batch operations)
function Invoke-ScriptSilent {
    param(
        [string]$ScriptName,
        [string]$DisplayName,
        [string]$Progress
    )
    
    Write-Host ""
    Write-Host "[$Progress] Running $DisplayName..." -ForegroundColor Green
    
    try {
        Write-Host "Fetching $ScriptName..." -ForegroundColor Cyan
        $script = Invoke-RestMethod -Uri "$GITHUB_BASE/$ScriptName"
        if ($script) {
            Invoke-Expression $script
        } else {
            throw "Empty script received"
        }
    } catch {
        Write-Host "Failed to run ${DisplayName}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to list available scripts
function Show-AvailableScripts {
    Write-Host ""
    Write-Host "Checking available scripts on GitHub..." -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "Available Scripts:" -ForegroundColor Green
        Write-Host "==================" -ForegroundColor Green
        
        $api_url = $GITHUB_BASE.Replace('/raw.githubusercontent.com/', '/api.github.com/repos/').Replace('/main/Scripts', '/contents/Scripts')
        $scripts = Invoke-RestMethod -Uri $api_url
        
        foreach ($script in $scripts) {
            if ($script.name -like "*.ps1") {
                Write-Host "  - $($script.name)" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "Could not fetch script list from GitHub" -ForegroundColor Red
        Write-Host "Manual script list:" -ForegroundColor Yellow
        Write-Host "  - $script_winget"
        Write-Host "  - $script_online_apps"
        Write-Host "  - $script_offline_apps"
        Write-Host "  - $script_tweaks"
        Write-Host "  - $script_bloatware"
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to run custom script
function Invoke-CustomScript {
    Write-Host ""
    Write-Host "Available scripts:" -ForegroundColor Green
    Write-Host "- $script_winget"
    Write-Host "- $script_online_apps"
    Write-Host "- $script_offline_apps"
    Write-Host "- $script_tweaks"
    Write-Host "- $script_bloatware"
    Write-Host ""
    
    $custom_script = Read-Host "Enter script filename (e.g., Custom_Script.ps1)"
    if ([string]::IsNullOrWhiteSpace($custom_script)) {
        return
    }
    
    Invoke-ScriptFromGitHub -ScriptName $custom_script -DisplayName "Custom Script"
}

# Function to run all scripts
function Invoke-AllScripts {
    Write-Host ""
    Write-Host "Running all setup tasks from GitHub..." -ForegroundColor Yellow
    Write-Host "WARNING: This will download and run all scripts automatically." -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Are you sure you want to continue? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        return
    }
    
    Write-Host ""
    Invoke-ScriptSilent -ScriptName $script_winget -DisplayName "WinGet Installer" -Progress "1/5"
    Invoke-ScriptSilent -ScriptName $script_online_apps -DisplayName "Online App Installer" -Progress "2/5"
    Invoke-ScriptSilent -ScriptName $script_offline_apps -DisplayName "Offline App Installer" -Progress "3/5"
    Invoke-ScriptSilent -ScriptName $script_tweaks -DisplayName "Performance Tweaks" -Progress "4/5"
    Invoke-ScriptSilent -ScriptName $script_bloatware -DisplayName "Bloatware Remover" -Progress "5/5"
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "All tasks completed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main script loop
do {
    $choice = Show-Menu
    
    switch ($choice) {
        "1" { Invoke-ScriptFromGitHub -ScriptName $script_winget -DisplayName "WinGet Installer" }
        "2" { Invoke-ScriptFromGitHub -ScriptName $script_online_apps -DisplayName "Online App Installer" }
        "3" { Invoke-ScriptFromGitHub -ScriptName $script_offline_apps -DisplayName "Offline App Installer" }
        "4" { Invoke-ScriptFromGitHub -ScriptName $script_tweaks -DisplayName "Performance Tweaks" }
        "5" { Invoke-ScriptFromGitHub -ScriptName $script_bloatware -DisplayName "Bloatware Remover" }
        "6" { Invoke-AllScripts }
        "7" { Show-AvailableScripts }
        "8" { Invoke-CustomScript }
        "0" { 
            Write-Host ""
            Write-Host "Resetting Execution Policy to Restricted..." -ForegroundColor Yellow
            try {
                Set-ExecutionPolicy Restricted -Scope LocalMachine -Force
            } catch {
                Write-Host "Could not reset execution policy: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            Write-Host ""
            Write-Host "Thank you for using Windows Auto Setup Toolkit!" -ForegroundColor Green
            Write-Host "Exiting in 3 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            exit
        }
        default { 
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
