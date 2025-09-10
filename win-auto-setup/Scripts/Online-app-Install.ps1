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
