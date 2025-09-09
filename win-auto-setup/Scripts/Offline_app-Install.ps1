$exes = Get-ChildItem -Path . -Filter *.exe
$total = $exes.Count
$count = 0
Write-Host "Found $total EXE files to install`n" -ForegroundColor Cyan

# Phase 1: Install all EXE files
foreach ($exe in $exes) {
    $count++
    Write-Progress -Activity "Installing Applications" -Status "[$count/$total] $($exe.Name)" -PercentComplete (($count / $total) * 100)
    
    Write-Host "Installing $($exe.Name)..." -ForegroundColor Yellow
    Start-Process -FilePath $exe.FullName -ArgumentList "/S" -Wait -NoNewWindow
    Write-Host "✓ Completed: $($exe.Name)" -ForegroundColor Green
}
Write-Progress -Activity "Installing Applications" -Completed

# User prompt for winget upgrade
Write-Host "Do you want to check for updates and run 'winget upgrade'?" -ForegroundColor Magenta
$choice = Read-Host "(Y/N)"

$internetStatus = Test-NetConnection -ComputerName "www.google.com" -InformationLevel Quiet
if ($internetStatus) {
            Write-Host "✓ Internet connection available. Proceeding with winget operations..." -ForegroundColor Green
            
        if ($choice -match '^(?i)y(es)?$') {
            try {                 
        
                Write-Host "CHECKING FOR AVAILABLE UPDATES" -ForegroundColor Yellow
        
        
                # Method 2: Check for upgrades
                winget upgrade --all
        
                Write-Host "`nInstallation and upgrade check completed! Use 'winget upgrade --all' to update all packages." -ForegroundColor Cyan

            } catch {
                Write-Host "Error running winget commands: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "`nUser chose not to run winget upgrade. Script completed." -ForegroundColor Yellow
            Write-Host "Installation finished successfully!" -ForegroundColor Green
            Exit
        }
}else {
            Write-Host "✗ No internet connection detected. Cannot run winget operations." -ForegroundColor Red
            }