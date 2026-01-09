$GITHUB_BASE = "https://raw.githubusercontent.com/SunriseComputers/PowerShell/main/win-auto-setup/Scripts"

# Set execution policy to Unrestricted
try {
    # Try CurrentUser scope first (less intrusive)
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction SilentlyContinue
}
catch {
    try {
        # Fallback to Process scope if CurrentUser fails
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force -ErrorAction SilentlyContinue
    }
    catch {
        # Silent failure - script will continue
    }
}

# Unblock all PowerShell files in the script directory to prevent security warnings
try {
    $scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    Get-ChildItem -Path $scriptPath -Recurse -Include *.ps1 -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
}
catch {
    # Silent failure - not critical if unblocking fails
}

# Get the script's directory for local file paths
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { "." }
$LocalScriptsPath = Join-Path $ScriptRoot "Scripts"

$scripts = @{
    "1" = @{ Name = "Install WinGet"; File = "Winget_Install.ps1" }
    "2" = @{ Name = "Install Apps (Online)"; File = "Online-app-Install.ps1" }
    "3" = @{ Name = "Apply Performance Tweaks"; File = "Performance-Tweaks-noUI.ps1" }
    "4" = @{ Name = "Stop Automatic Windows Updates"; File = "Delay-WindowsUpdates.ps1" }
    "6" = @{ Name = "Lanman Network Tweaks"; File = "Lanman_Network.ps1" }
    "7" = @{ Name = "Reset SMB Connection"; File = "SMB-Connection-Reset.ps1" }
    "8" = @{ Name = "Ethernet Link Speed"; File = "link-speed.ps1" }
    "9" = @{ Name = "Permanent Disable Windows Update"; File = "Disable-WindowsUpdates.ps1" }
    "A" = @{ Name = "Run All Scripts"; File = "" }
    "H" = @{ Name = "Hardware Information"; File = "Hardware_Report_Generator.ps1" }
}

# Function to find script path (local first, then fallback)
function Get-ScriptPath {
    param([string]$ScriptFile)
    
    $localPaths = @(
        (Join-Path $LocalScriptsPath $ScriptFile),
        ".\Scripts\$ScriptFile",
        ".\$ScriptFile"
    )
    
    foreach ($path in $localPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# Function to check if running locally
function Test-LocalEnvironment {
    return (Test-Path $LocalScriptsPath)
}
# Function to run script (local first, then GitHub fallback)
function Invoke-Script {
    param([string]$ScriptFile, [string]$ScriptName)
    
    $localPath = Get-ScriptPath $ScriptFile
    
    if ($localPath) {
        Write-Host "`nRunning: $ScriptName (Local)..." -ForegroundColor Green
        try {
            & $localPath
            Write-Host "`n$ScriptName completed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "`nError running local script: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Attempting GitHub fallback..." -ForegroundColor Yellow
            $localPath = $null
        }
    }
    
    if (-not $localPath) {
        Write-Host "`nDownloading from GitHub..." -ForegroundColor Yellow
        try {
            $script = Invoke-RestMethod -Uri "$GITHUB_BASE/$ScriptFile"
            Invoke-Expression $script
            Write-Host "`n$ScriptName completed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "`nError: Could not download or run $ScriptFile from GitHub" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
    
    Read-Host "`nPress Enter to continue"
}


# Function to run all scripts
function Invoke-AllScripts {
    Write-Host "`nRunning all scripts in sequence..." -ForegroundColor Cyan
    Write-Host "WARNING: This will run scripts 1-4 one-by-one" -ForegroundColor Red

    if (Test-LocalEnvironment) {
        Write-Host "Local environment detected" -ForegroundColor Green
    }
    else {
        Write-Host "Remote environment - downloading from GitHub" -ForegroundColor Yellow
    }

    Write-Host "`nThis will:" -ForegroundColor Blue
    Write-Host "1. Install WinGet (if needed)"
    Write-Host "2. Install essential applications"
    Write-Host "3. Apply performance tweaks"
    Write-Host "4. Stop automatic Windows updates"
    
    $confirm = Read-Host "`nContinue? (Y/N)"
    
    if ($confirm -eq "Y" -or $confirm -eq "y") {
        foreach ($key in @("1", "2", "3", "4")) {
            $scriptFile = $scripts[$key].File
            $scriptName = $scripts[$key].Name
            
            Write-Host "`n[$key/4] Running: $scriptName..." -ForegroundColor Yellow
            
            $localPath = Get-ScriptPath $scriptFile
            
            if ($localPath) {
                try {
                    & $localPath
                    Write-Host "$scriptName - Completed (Local)" -ForegroundColor Green
                }
                catch {
                    Write-Host "$scriptName - Failed (Local): $($_.Exception.Message)" -ForegroundColor Red
                    $localPath = $null
                }
            }
            
            if (-not $localPath) {
                try {
                    $script = Invoke-RestMethod -Uri "$GITHUB_BASE/$scriptFile"
                    Invoke-Expression $script
                    Write-Host "$scriptName - Completed (GitHub)" -ForegroundColor Green
                }
                catch {
                    Write-Host "$scriptName - Failed (GitHub): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        Write-Host "`nAll scripts completed!" -ForegroundColor Green
    }
    
    Read-Host "`nPress Enter to continue"
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
    }
    else {
        Write-Host "  [REMOTE MODE] - Downloading scripts from GitHub" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Main options
    foreach ($key in @("1", "2", "3", "4", "A", "9")) {
        # removed 5
        Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
    }

    # Network Related Settings section
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "  Network Related Settings`n" -ForegroundColor Cyan
    Write-Host "  Run At Your Own Risk!" -ForegroundColor Red
    Write-Host "  These tweaks may disrupt network connectivity." -ForegroundColor Red
    foreach ($key in @("6", "7", "8")) {
        Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
    }

    # Hardware Information section
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "  System Information`n" -ForegroundColor Cyan
    Write-Host "  This section provides information about the system hardware." -ForegroundColor Blue
    foreach ($key in @("H")) {
        Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
    }
    
    Write-Host "`n  [0] Exit" -ForegroundColor Gray
    return Read-Host "`nChoose an option"
}

# Main loop
do {
    $choice = Show-Menu
    
    if ($choice -eq "A") {
        Invoke-AllScripts
    }
    elseif ($scripts.ContainsKey($choice) -and $choice -ne "A") {
        Invoke-Script -ScriptFile $scripts[$choice].File -ScriptName $scripts[$choice].Name
    }
    elseif ($choice -eq "0") {
        Write-Host "`n  Thank You For Using Our Services" -ForegroundColor Magenta
        Write-Host "  Sunrise Computers" -ForegroundColor Magenta
        Write-Host "`n  Exiting..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        exit
    }
    else {
        Write-Host "`nInvalid option. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
} while ($true)
