if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
Write-Host “Requesting administrative privileges…” -ForegroundColor Yellow
Start-Process powershell.exe “-NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath”” -Verb RunAs
exit
}

# Set execution policy for current session only

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Clear screen and set colors

Clear-Host
$Host.UI.RawUI.BackgroundColor = “Black”
$Host.UI.RawUI.ForegroundColor = “Green”

# ASCII Art Header

Write-Host @”

-----

/ ****|                           / ****|                          | |  
| (***  _   _ _ __ ___ _ __   _     | |     ___  _ __ ___  _ __  _   | | ___ _ __ ___
_** | | | | ’* _ \| '_ \ (_)   | |    / _ \| '_ _ | ’* | | | | */ _ | ’*/ **|
***) | || | | | | | | |) |     | || () | | | | | | |) | || | ||  **/| |  _*   
|/ _*,|| || || ./()     _*____**/|| || || ./ _,|_||  |*/
| |                                | |  
||                                ||

Performance Computing - Since 2001

“@ -ForegroundColor Cyan

Write-Host “GitHub PowerShell Script Launcher - One-liner execution style” -ForegroundColor Yellow
Write-Host “================================================================” -ForegroundColor White

# GitHub Configuration - UPDATE THESE TO YOUR REPOSITORY

$GITHUB_USER = “SunriseComputers”
$GITHUB_REPO = “PowerShell”
$GITHUB_BRANCH = “main”
$SCRIPT_PATH = “win-auto-setup/Scripts”  # folder path in your repo, leave empty if scripts are in root

# Construct base URL

$GITHUB_BASE = if (win-auto-setup/Scripts) {
“https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts”
} else {
“https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts/”
}

# Your script definitions - UPDATE WITH YOUR ACTUAL SCRIPT NAMES

$scripts = @{
“1” = @{
name = “Winget_Install.ps1”
description = “Install WinGet Package Manager”
oneliner = “irm "https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts/Winget_Install.ps1” | iex”
}
“2” = @{
name = “Online-app-Install.ps1”
description = “Install Apps (Online Method)”
oneliner = “irm "https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts/Online-app-Install.ps1” | iex”
}
“3” = @{
name = “Offline-app_Install.ps1”
description = “Install Apps (Offline Method)”
oneliner = “irm "https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts/Offline-app_Install.ps1” | iex”
}
“4” = @{
name = “Performance_Tweaks.ps1”
description = “Apply Windows Performance Tweaks”
oneliner = “irm "https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts/Performance_Tweaks.ps1” | iex”
}
“5” = @{
name = “App_Remover.ps1”
description = “Remove Windows Bloatware”
oneliner = “irm "https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts/App_Remover.ps1” | iex”
}
“6” = @{
name = “System_Cleanup.ps1”
description = “System Cleanup & Optimization”
oneliner = “irm "https://github.com/SunriseComputers/PowerShell/tree/main/win-auto-setup/Scripts/System_Cleanup.ps1” | iex”
}
}

# Function to execute script like Chris Titus/MAS style

function Invoke-RemoteScript {
param(
[string]$ScriptKey,
[switch]$ShowOneLiner = $false
)


if (-not $scripts.ContainsKey($ScriptKey)) {
    Write-Host "Invalid script selection!" -ForegroundColor Red
    return
}

$script = $scripts[$ScriptKey]
$url = "$GITHUB_BASE/$($script.name)"

if ($ShowOneLiner) {
    Write-Host "`nOne-liner command for this script:" -ForegroundColor Yellow
    Write-Host $script.oneliner -ForegroundColor Cyan
    Write-Host "`nCopy and paste this command in any PowerShell window (Admin required)" -ForegroundColor Green
    return
}

Write-Host "`nExecuting: $($script.description)" -ForegroundColor Cyan
Write-Host "URL: $url" -ForegroundColor Gray
Write-Host "Command: irm `"$url`" | iex" -ForegroundColor Gray
Write-Host ("-" * 60) -ForegroundColor White

try {
    # This is the Chris Titus/MAS style execution
    irm $url | iex
    Write-Host "`n$($script.description) completed!" -ForegroundColor Green
}
catch {
    Write-Host "`nError executing script:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host "`nTrying alternative method..." -ForegroundColor Yellow
    
    try {
        # Fallback method
        $scriptContent = Invoke-RestMethod -Uri $url
        Invoke-Expression $scriptContent
    }
    catch {
        Write-Host "Alternative method also failed:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}


}

# Function to show one-liners for all scripts

function Show-OneLiners {
Write-Host “`n” + (”=” * 80) -ForegroundColor Cyan
Write-Host “ONE-LINER COMMANDS - Copy & Paste in PowerShell (Admin)” -ForegroundColor Yellow
Write-Host (”=” * 80) -ForegroundColor Cyan


foreach ($key in $scripts.Keys | Sort-Object) {
    $script = $scripts[$key]
    Write-Host "`n[$key] $($script.description)" -ForegroundColor White
    Write-Host $script.oneliner -ForegroundColor Cyan
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "How to use: Copy any line above and paste in PowerShell (Run as Administrator)" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan


}

# Function to run all scripts in sequence

function Invoke-AllScripts {
Write-Host “`nRUNNING ALL SCRIPTS IN SEQUENCE” -ForegroundColor Yellow
Write-Host “WARNING: This will execute all scripts automatically!” -ForegroundColor Red


$confirm = Read-Host "`nContinue? (y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    return
}

$totalScripts = $scripts.Count
$currentScript = 0

foreach ($key in $scripts.Keys | Sort-Object) {
    $currentScript++
    $script = $scripts[$key]
    
    Write-Host "`n" + ("=" * 60) -ForegroundColor White
    Write-Host "[$currentScript/$totalScripts] $($script.description)" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor White
    
    try {
        irm "$GITHUB_BASE/$($script.name)" | iex
        Write-Host "✓ Completed: $($script.description)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed: $($script.description)" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 2
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Green
Write-Host "ALL SCRIPTS EXECUTION COMPLETED!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green


}

# Main menu loop

do {
Write-Host “`n” + (”=” * 60) -ForegroundColor White
Write-Host “WINDOWS POWERSHELL SCRIPT LAUNCHER” -ForegroundColor White
Write-Host “Chris Titus Tech / MAS Style Execution” -ForegroundColor Gray
Write-Host (”=” * 60) -ForegroundColor White


foreach ($key in $scripts.Keys | Sort-Object) {
    Write-Host "[$key] $($scripts[$key].description)" -ForegroundColor White
}

Write-Host "`n[A] Run All Scripts" -ForegroundColor Yellow
Write-Host "[O] Show One-liner Commands" -ForegroundColor Cyan
Write-Host "[C] Show Custom Script Command" -ForegroundColor Magenta
Write-Host "[U] Update GitHub Configuration" -ForegroundColor Blue
Write-Host "[Q] Quit" -ForegroundColor Red
Write-Host ("=" * 60) -ForegroundColor White

$choice = Read-Host "Select option"

switch ($choice.ToUpper()) {
    {$_ -in $scripts.Keys} {
        Invoke-RemoteScript -ScriptKey $_
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
    "A" {
        Invoke-AllScripts
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
    "O" {
        Show-OneLiners
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
    "C" {
        Write-Host "`nEnter your script filename (e.g., My_Script.ps1):" -ForegroundColor Yellow
        $customScript = Read-Host
        if ($customScript) {
            $customUrl = "$GITHUB_BASE/$customScript"
            Write-Host "`nOne-liner for your custom script:" -ForegroundColor Cyan
            Write-Host "irm `"$customUrl`" | iex" -ForegroundColor Green
            Write-Host "`nExecute now? (y/N)" -ForegroundColor Yellow
            $execute = Read-Host
            if ($execute -eq 'y' -or $execute -eq 'Y') {
                try {
                    irm $customUrl | iex
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
    "U" {
        Write-Host "`nCurrent Configuration:" -ForegroundColor Yellow
        Write-Host "User: $GITHUB_USER" -ForegroundColor White
        Write-Host "Repo: $GITHUB_REPO" -ForegroundColor White
        Write-Host "Branch: $GITHUB_BRANCH" -ForegroundColor White
        Write-Host "Script Path: $SCRIPT_PATH" -ForegroundColor White
        Write-Host "Base URL: $GITHUB_BASE" -ForegroundColor Cyan
        Write-Host "`nEdit the script file to update configuration." -ForegroundColor Gray
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
    "Q" { 
        break 
    }
    default {
        Write-Host "Invalid selection!" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}


} while ($true)

Write-Host “`nThank you for using the PowerShell Script Launcher!” -ForegroundColor Green
Write-Host “Visit: https://github.com/$GITHUB_USER/$GITHUB_REPO” -ForegroundColor Cyan
