

# WinGet Version Checker and Updater

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

Winget Upgrade Winget --accept-source-agreements --accept-package-agreements

Write-Host "Winget Update Process Completed" -ForegroundColor Magenta

Write-Host "Now, Installing Your Selected Apps" -ForegroundColor Cyan
$apps = @(
    "Google.Chrome",
    "SumatraPDF.SumatraPDF",
    "7zip.7zip",
    "VideoLAN.VLC"
    )
# -----------------------------------------------------

foreach ($app in $apps) {
    Write-Host "Checking $app ..." -ForegroundColor Cyan

    # Is the package already installed?
    $isInstalled = winget list --id $app --exact 2>$null |
               Select-String -SimpleMatch -Quiet $app
    if ($isInstalled) {
        Write-Host "$app already installed – skipping.`n" -ForegroundColor Green
        continue
    }

    # Install the package
    Write-Host "Installing $app ..." -ForegroundColor Yellow
    winget install --id $app `
                   --exact `
                   --silent `
                   --accept-source-agreements `
                   --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$app installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to install $app (exit code $LASTEXITCODE)." -ForegroundColor Red
    }
}

Write-Host "Thank You For Using Our Services" -ForegroundColor Magenta
Write-Host "Sunrise Computers" -ForegroundColor Magenta

Write-Host
Read-Host "Press Enter to exit"