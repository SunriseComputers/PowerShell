$GITHUB_BASE = "https://raw.githubusercontent.com/SunriseComputers/PowerShell/main/win-auto-setup/Scripts"

# Get the script's directory for local file paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LocalScriptsPath = Join-Path $ScriptRoot "Scripts"

$scripts = @{
    "1" = @{ Name = "Install WinGet"; File = "Winget_Install.ps1" }
    "2" = @{ Name = "Install Apps (Online)"; File = "Online-app-Install.ps1" }
    "3" = @{ Name = "Apply Performance Tweaks"; File = "Perfomance-Tweaks-noUI.ps1" }
    "4" = @{ Name = "Stop Automatic Windows Updates"; File = "Delay-WindowsUpdates.ps1" }
    # "5" = @{ Name = "Remove Bloatware"; File = "App_Remover.ps1" }
    "6" = @{ Name = "Lanman Network Tweaks"; File = "Lanman_Network.ps1" }
    "7" = @{ Name = "Reset SMB Connection"; File = "SMB-Connection-Reset.ps1" }
    "8" = @{ Name = "Ethernet Link Speed"; File = "link-speed.ps1" }
    "9" = @{ Name = "Permanent Disable Windows Update"; File = "Disable-WindowsUpdates.ps1" }
    "A" = @{ Name = "Run All Scripts"; File = "" }
    "H" = @{ Name = "Hardware Information"; File = "Hardware_Report_Generator.ps1" }
}

# Function to check if running locally
function Test-LocalEnvironment {
    return (Test-Path $LocalScriptsPath)
}

# Function to show local scripts status
function Show-LocalScriptsStatus {
    Write-Host "`nLocal Scripts Status:" -ForegroundColor Cyan
    Write-Host "Scripts Folder: $LocalScriptsPath" -ForegroundColor Gray
    
    if (Test-LocalEnvironment) {
        Write-Host "[OK] Scripts folder found" -ForegroundColor Green
        
        # Check each script
        foreach ($key in $scripts.Keys) {
            if ($scripts[$key].File -ne "") {
                $scriptFile = $scripts[$key].File
                $localPath = Join-Path $LocalScriptsPath $scriptFile
                
                if (Test-Path $localPath) {
                    Write-Host "  [OK] $scriptFile" -ForegroundColor Green
                } else {
                    Write-Host "  [MISSING] $scriptFile (will use GitHub)" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "[ERROR] Scripts folder not found - will use GitHub for all scripts" -ForegroundColor Yellow
    }
    
    Write-Host "`nPress any key to return to menu..." -ForegroundColor Yellow
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Read-Host "Press Enter to continue" | Out-Null
    }
}

# Function to run script (local first, then GitHub fallback)
function Invoke-Script {
    param([string]$ScriptFile, [string]$ScriptName)
    
    # Try multiple local path options
    $localPaths = @(
        (Join-Path $LocalScriptsPath $ScriptFile),  # Scripts subfolder
        (Join-Path $ScriptRoot $ScriptFile),        # Same directory as main.ps1
        ".\Scripts\$ScriptFile",                    # Relative Scripts folder
        ".\$ScriptFile"                             # Current directory
    )
    
    $foundLocal = $false
    $localPath = ""
    
    # Check for local script existence
    foreach ($path in $localPaths) {
        if (Test-Path $path) {
            $foundLocal = $true
            $localPath = $path
            break
        }
    }
    
    if ($foundLocal) {
        Write-Host "`nRunning: $ScriptName (Local)..." -ForegroundColor Green
        Write-Host "Path: $localPath" -ForegroundColor Gray
        try {
            # Set location to script directory for relative path resolution
            $originalLocation = Get-Location
            Set-Location (Split-Path $localPath -Parent)
            
            & $localPath
            Write-Host "`n$ScriptName completed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "`nError running local script: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Attempting GitHub fallback..." -ForegroundColor Yellow
            $foundLocal = $false  # Force GitHub fallback
        } finally {
            # Restore original location
            Set-Location $originalLocation
        }
    }
    
    # Fallback to GitHub if local not found or failed
    if (-not $foundLocal) {
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
    Write-Host "WARNING: This will run all scripts from 1-4 one-by-one" -ForegroundColor Red

    # Show environment status
    if (Test-LocalEnvironment) {
        Write-Host "Local environment detected - will use local scripts when available" -ForegroundColor Green
        Write-Host "Scripts folder: $LocalScriptsPath" -ForegroundColor Gray
    } else {
        Write-Host "Remote environment - will download scripts from GitHub" -ForegroundColor Yellow
    }

    Write-Host "`n1. WE will Install the Latest Version of Winget, Skip if already installed." -ForegroundColor Blue 
    Write-Host "2. We will Install Essential Applications, which include the following apps -" -ForegroundColor Blue
    Write-Host "   - Mozilla Firefox"
    Write-Host "   - SumatraPDF"
    Write-Host "   - 7zip"
    Write-Host "   - VLC Media Player"
    Write-Host "   - UltraViewer"
    Write-Host "3. We will Apply  the following Performance Tweaks." -ForegroundColor Blue
    Write-Host "   - Disable Snap Assist Flyout"
    Write-Host "   - Delete Temporary Files"
    Write-Host "   - Disable ConsumerFeatures"
    Write-Host "   - Disable Telemetry"
    Write-Host "   - Disable Activity History"
    Write-Host "   - Disable Explorer Automatic Folder Discovery"
    Write-Host "   - Disable GameDVR"
    Write-Host "   - Disable Homegroup"
    Write-Host "   - Disable Location Tracking"
    Write-Host "   - Disable Storage Sense"
    Write-Host "   - Disable Wi-Fi Sense"
    Write-Host "   - Enable End Task With Right Click"
    Write-Host "   - Set Services to Manual"
    Write-Host "   - Enable Dark Mode"
    Write-Host "   - Set Classic Right-Click Menu"
    Write-Host "4. Stop Automatic Windows Updates" -ForegroundColor Blue
    Write-Host "   - a. This Will Change the Windows Update Setting to Manual, which means it will only Update Windows when you click on 'Check Updates' inside the Settings App."
    Write-Host "   - b. This Delay Your Security Udpates to few day. If you do a manual update it will work normally."
    # Write-Host "5. This will open a new windows where you can select the Apps that you don't want and remove them." -ForegroundColor Blue
    
    $confirm = Read-Host "Continue? (Y/N)"
    
    if ($confirm -eq "Y" -or $confirm -eq "y") {
        $scriptOrder = @("1", "2", "3", "4") #removed 5- Bloatware Remover
        
        foreach ($key in $scriptOrder) {
            $scriptFile = $scripts[$key].File
            $scriptName = $scripts[$key].Name
            
            # Try multiple local path options
            $localPaths = @(
                (Join-Path $LocalScriptsPath $scriptFile),
                (Join-Path $ScriptRoot $scriptFile),
                ".\Scripts\$scriptFile",
                ".\$scriptFile"
            )
            
            $foundLocal = $false
            $localPath = ""
            
            foreach ($path in $localPaths) {
                if (Test-Path $path) {
                    $foundLocal = $true
                    $localPath = $path
                    break
                }
            }
            
            Write-Host "`n[$key/4] Running: $scriptName..." -ForegroundColor Yellow
            
            if ($foundLocal) {
                Write-Host "Using local script: $localPath" -ForegroundColor Gray
                try {
                    $originalLocation = Get-Location
                    Set-Location (Split-Path $localPath -Parent)
                    & $localPath
                    Write-Host "$scriptName - Completed (Local)" -ForegroundColor Green
                } catch {
                    Write-Host "$scriptName - Failed (Local): $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Attempting GitHub fallback..." -ForegroundColor Yellow
                    $foundLocal = $false
                } finally {
                    Set-Location $originalLocation
                }
            }
            
            # GitHub fallback
            if (-not $foundLocal) {
                Write-Host "Downloading from GitHub..." -ForegroundColor Gray
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
        Write-Host "`nReturning to menu..." -ForegroundColor Yellow
        return
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
Write-Host "  Performance Computing" -ForegroundColor Cyan
Write-Host "  Since 2001 `n"

    # Show environment status
    if (Test-LocalEnvironment) {
        Write-Host "  [LOCAL MODE] - Using scripts from: Scripts\" -ForegroundColor Green
    } else {
        Write-Host "  [REMOTE MODE] - Downloading scripts from GitHub" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Main options
    foreach ($key in @("1","2","3","4","A","9"))  # removed 5
    {
        Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
    }

    # Network Related Settings section
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "  Network Related Settings`n" -ForegroundColor Cyan
    Write-Host "  Run At Your Own Risk!" -ForegroundColor Red
    Write-Host "  These tweaks may disrupt network connectivity." -ForegroundColor Red
    foreach ($key in @("6","7","8")) {
        Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
    }

    # Hardware Information section
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "  System Information`n" -ForegroundColor Cyan
    Write-Host "  This section provides information about the system hardware." -ForegroundColor Blue
    foreach ($key in @("H")) {
        Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
    }

    # Local Scripts Status section
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "  Local Environment`n" -ForegroundColor Cyan
    Write-Host "  [L] Show Local Scripts Status" -ForegroundColor White

    Write-Host "`n  [0] Exit`n"-ForegroundColor Red
    $choice = Read-Host "  Choose an option"
    return $choice
}

# Main loop
do {
    $choice = Show-Menu
    
    if ($choice -eq "A") {
        Invoke-AllScripts
    } elseif ($choice -eq "L" -or $choice -eq "l") {
        Show-LocalScriptsStatus
    } elseif ($scripts.ContainsKey($choice) -and $choice -ne "A") {
        Invoke-Script -ScriptFile $scripts[$choice].File -ScriptName $scripts[$choice].Name
    } elseif ($choice -eq "0") {
        Write-Host "`n  Thank You For Using Our Services" -ForegroundColor Magenta
        Write-Host "  Sunrise Computers" -ForegroundColor Magenta
        Write-Host "`n  Exiting..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        Stop-Process -Id $PID -Force
    } else {
        Write-Host "`nInvalid option. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
} while ($true)
