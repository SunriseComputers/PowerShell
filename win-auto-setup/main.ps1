$GITHUB_BASE = "https://raw.githubusercontent.com/SunriseComputers/PowerShell/main/win-auto-setup/Scripts"
$scripts = @{
    "1" = @{ Name = "Install WinGet"; File = "Winget_Install.ps1" }
    "2" = @{ Name = "Install Apps (Online)"; File = "Online-app-Install.ps1" }
    "3" = @{ Name = "Apply Performance Tweaks"; File = "Perfomance_Tweaks.ps1" }
    "4" = @{ Name = "Stop Automatic Windows Updates"; File = "Delay-WindowsUpdates.ps1" }
    "5" = @{ Name = "Remove Bloatware"; File = "App_Remover.ps1" }
    "6" = @{ Name = "Lanman Network Tweaks"; File = "Lanman_Network.ps1" }
    "7" = @{ Name = "Reset SMB Connection"; File = "SMB-Connection-Reset.ps1" }
    "8" = @{ Name = "Ethernet Link Speed"; File = "link-speed.ps1" }
    "A" = @{ Name = "Run All Scripts"; File = "" }
    "H" = @{ Name = "Hardware Information"; File = "Hardware_Report_Generator.ps1" }
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
    Write-Host "WARNING: This will run all scripts from 1-5 one-by-one" -ForegroundColor Red

    Write-Host "1. WE will Install the Latest Version of Winget, Skip if already installed." -ForegroundColor Blue 
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
    Write-Host "5. This will open a new windows where you can select the Apps that you don't want and remove them." -ForegroundColor Blue
    
    $confirm = Read-Host "Continue? (Y/N)"
    
    if ($confirm -eq "Y" -or $confirm -eq "y") {
        $scriptOrder = @("1", "2", "3", "4","5")
        
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
        Write-Host "\nReturning to menu..." -ForegroundColor Yellow
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
    
    # Main options
    foreach ($key in @("1","2","3","4","5","A","H")) {
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
    Write-Host "  This section provides information about the system hardware." -ForegroundColor Yellow
    foreach ($key in @("H")) {
        Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
    }

    Write-Host "`n  [0] Exit`n"-ForegroundColor Red
    $choice = Read-Host "  Choose an option"
    return $choice
}

# Main loop
do {
    $choice = Show-Menu
    
    if ($choice -eq "A") {
        Invoke-AllScripts
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
