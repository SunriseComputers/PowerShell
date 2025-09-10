#Requires -RunAsAdministrator

# Configuration
$GITHUB_BASE = "https://raw.githubusercontent.com/SunriseComputers/PowerShell/main/win-auto-setup/Scripts"
$scripts = @{
    "1" = @{ Name = "Install WinGet"; File = "Winget_Install.ps1" }
    "2" = @{ Name = "Install Apps (Online)"; File = "Online-app-Install.ps1" }
    "3" = @{ Name = "Install Apps (Offline)"; File = "Offline_app-Install.ps1" }
    "4" = @{ Name = "Apply Performance Tweaks"; File = "Perfomance_Tweaks.ps1" }
    "5" = @{ Name = "Remove Bloatware"; File = "App_Remover.ps1" }
    "6" = @{ Name = "Run All Scripts"; File = "" }
}

# Function to run script (local first, then GitHub fallback)
function Invoke-Script {
    param([string]$ScriptFile, [string]$ScriptName)
    
    $localPath = ".\$ScriptFile"
    
    # Try local first
    if (Test-Path $localPath) {
        Write-Host "`nRunning: $ScriptName (Local)..." -ForegroundColor Green
        try {
            & $localPath
            Write-Host "`n$ScriptName completed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "`nError running local script: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        # Fallback to GitHub
        Write-Host "`nLocal script not found. Downloading from GitHub..." -ForegroundColor Yellow
        Write-Host "Running: $ScriptName (GitHub)..." -ForegroundColor Green
        
        try {
            $script = Invoke-RestMethod -Uri "$GITHUB_BASE/$ScriptFile"
            if ($script) {
                Invoke-Expression $script
                Write-Host "`n$ScriptName completed successfully!" -ForegroundColor Green
            } else {
                throw "Empty script received"
            }
        } catch {
            Write-Host "`nError: Could not download or run $ScriptFile from GitHub" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nPress any key to return to menu..." -ForegroundColor Yellow
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Read-Host "Press Enter to continue" | Out-Null
    }
}

# Function to run all scripts (local first, then GitHub fallback)
function Invoke-AllScripts {
    Write-Host "`nRunning all scripts in sequence..." -ForegroundColor Cyan
    Write-Host "WARNING: This will run all 5 scripts automatically." -ForegroundColor Red
    $confirm = Read-Host "Continue? (Y/N)"
    
    if ($confirm -eq "Y" -or $confirm -eq "y") {
        $scriptOrder = @("1", "2", "3", "4", "5")
        
        foreach ($key in $scriptOrder) {
            $scriptFile = $scripts[$key].File
            $scriptName = $scripts[$key].Name
            $localPath = ".\$scriptFile"
            
            Write-Host "`n[$key/5] Running: $scriptName..." -ForegroundColor Yellow
            
            # Try local first
            if (Test-Path $localPath) {
                Write-Host "Using local script..." -ForegroundColor Gray
                try {
                    & $localPath
                    Write-Host "$scriptName - Completed (Local)" -ForegroundColor Green
                } catch {
                    Write-Host "$scriptName - Failed (Local): $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                # Fallback to GitHub
                Write-Host "Local not found, downloading from GitHub..." -ForegroundColor Gray
                try {
                    $script = Invoke-RestMethod -Uri "$GITHUB_BASE/$scriptFile"
                    if ($script) {
                        Invoke-Expression $script
                        Write-Host "$scriptName - Completed (GitHub)" -ForegroundColor Green
                    } else {
                        throw "Empty script received"
                    }
                } catch {
                    Write-Host "$scriptName - Failed (GitHub): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        
        Write-Host "`nAll scripts completed!" -ForegroundColor Green
    } else {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
    }
    
    Write-Host "`nPress any key to return to menu..." -ForegroundColor Yellow
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Read-Host "Press Enter to continue" | Out-Null
    }
}

# Main menu function
function Show-Menu {
    Clear-Host
    Write-Host "   _____                  _             _____                            _                
  / ____|                (_)           / ____|                          | |               
 | (___  _   _ _ __  _ __ _ ___  ___  | |     ___  _ __ ___  _ __  _   _| |_ ___ _ __ ___ 
  \___ \| | | | '_ \| '__| / __|/ _ \ | |    / _ \| '_ ` _ \| '_ \| | | | __/ _ \ '__/ __|
  ____) | |_| | | | | |  | \__ \  __/ | |___| (_) | | | | | | |_) | |_| | ||  __/ |  \__ \
 |_____/ \__,_|_| |_|_|  |_|___/\___|  \_____\___/|_| |_| |_| .__/ \__,_|\__\___|_|  |___/
                                                            | |                           
                                                            |_|                           "-ForegroundColor Red
Write-Host "Performance Computing" -ForegroundColor Cyan
Write-Host "Since 2001 `n"
    
    foreach ($key in $scripts.Keys | Sort-Object) {
        Write-Host "[$key] $($scripts[$key].Name)" -ForegroundColor White
    }
    
    Write-Host "[0] Exit" -ForegroundColor Red
    Write-Host ""
    $choice = Read-Host "Choose an option"
    return $choice
}

# Main loop
do {
    $choice = Show-Menu
    
    if ($choice -eq "6") {
        Invoke-AllScripts
    } elseif ($scripts.ContainsKey($choice) -and $choice -ne "6") {
        Invoke-Script -ScriptFile $scripts[$choice].File -ScriptName $scripts[$choice].Name
    } elseif ($choice -eq "0") {
        Write-Host "`nExiting..." -ForegroundColor Yellow
        break
    } else {
        Write-Host "`nInvalid option. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
} while ($true)
