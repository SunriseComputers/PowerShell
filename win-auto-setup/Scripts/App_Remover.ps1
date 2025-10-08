# Interactive App Removal Tool - Fixed Version
# Based on Win11Debloat by Raphire
# This script now focuses on core app removal functionality
# UI integration is handled by UI_Main.ps1

# Check for administrator privileges
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "Administrator privileges required for app removal!" -ForegroundColor Yellow
    Write-Host "Attempting to restart with elevated privileges..." -ForegroundColor Cyan
    try {
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
        Exit 0
    } catch {
        Write-Host "Failed to start with administrator privileges. Please:" -ForegroundColor Red
        Write-Host "1. Right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        Write-Host "2. Navigate to this script location" -ForegroundColor Yellow
        Write-Host "3. Run the script again" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        Exit 1
    }
}

# Core app detection and removal functions

function Get-InstalledApps {
    $apps = @{}
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -and $_.UninstallString -and $_.SystemComponent -ne 1 -and
            $_.DisplayName -notmatch '^(Microsoft Visual C\+\+|Microsoft \.NET|Update for|Security Update|Hotfix|KB\d+)' -and
            $_.ReleaseType -ne "Security Update" -and $null -eq $_.ParentKeyName
        } | ForEach-Object {
            $cleanName = $_.DisplayName -replace '\s+\([^)]*\)$', ''
            $apps[$cleanName] = @{
                UninstallString = $_.UninstallString
                QuietUninstallString = $_.QuietUninstallString
                DisplayName = $_.DisplayName
                Type = "Registry"
            }
        }
    }
    return $apps
}

function Get-UWPApps {
    $apps = @{}
    try {
        # Get current user packages only - like Raphie's approach
        $packages = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notmatch '^(Microsoft\.Windows\.|Microsoft\.NET\.|Microsoft\.VCLibs|Microsoft\.UI\.Xaml|windows\.immersivecontrolpanel|Microsoft\.AAD\.BrokerPlugin|Microsoft\.AccountsControl)' -and
            -not $_.IsFramework -and $_.Status -eq "Ok" -and $_.SignatureKind -ne "System"
        }
        
        foreach ($package in $packages) {
            $displayName = if ($package.DisplayName) { $package.DisplayName } else { 
                $package.Name -replace '^Microsoft\.', '' -replace '\.', ' ' -replace 'App$', '' 
            }
            $apps[$displayName] = @{
                PackageName = $package.Name
                PackageFullName = $package.PackageFullName
                DisplayName = $displayName
                Publisher = $package.Publisher
                Type = "UWP"
            }
        }
    } catch { 
        Write-Warning "Failed to get UWP apps: $_" 
    }
    return $apps
}

function Get-AllInstalledApps {
    $allApps = Get-InstalledApps
    $uwpApps = Get-UWPApps
    foreach ($app in $uwpApps.GetEnumerator()) {
        $allApps[$app.Key] = $app.Value
    }
    return $allApps
}

function Remove-SelectedApps {
    param (
        [array]$AppsList,
        [hashtable]$AppRegistry
    )
    
    $removed = $failed = 0
    $totalApps = $AppsList.Count
    
    Write-Host "`nStarting app removal..." -ForegroundColor Cyan
    
    foreach ($app in $AppsList) {
        $appInfo = $AppRegistry[$app]
        Write-Host "Attempting to remove $($appInfo.DisplayName)..." -ForegroundColor Yellow
        
        try {
            if ($appInfo.Type -eq "UWP") {
                # UWP app removal - simplified like Raphie's approach
                $appPattern = '*' + $appInfo.PackageName + '*'
                
                # Remove for current user first
                try {
                    Get-AppxPackage -Name $appPattern | Remove-AppxPackage -ErrorAction Stop
                    Write-Host "Removed $($appInfo.DisplayName) for current user" -ForegroundColor Green
                } catch {
                    Write-Host "Unable to remove $($appInfo.DisplayName) for current user" -ForegroundColor Yellow
                }
                
                # Remove for all users (requires admin)
                try {
                    Get-AppxPackage -Name $appPattern -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Stop
                    Write-Host "Removed $($appInfo.DisplayName) for all users" -ForegroundColor Green
                } catch {
                    Write-Host "Unable to remove $($appInfo.DisplayName) for all users" -ForegroundColor Yellow
                }
                
                # Remove provisioned package
                try {
                    Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $appPattern } | ForEach-Object { 
                        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop
                    }
                } catch {
                    # Silent failure for provisioned packages
                }
                
                $removed++
            } else {
                # Registry app removal - simplified
                $uninstallCmd = if ($appInfo.QuietUninstallString) { $appInfo.QuietUninstallString } else { $appInfo.UninstallString }
                
                if ($uninstallCmd -match 'msiexec.*(/I|/X)\s*(\{[^}]+\})') {
                    # MSI uninstall
                    $productCode = $matches[2]
                    $process = Start-Process "msiexec.exe" -ArgumentList "/X$productCode", "/quiet", "/norestart" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1605 -or $process.ExitCode -eq 3010) {
                        Write-Host "Successfully removed $($appInfo.DisplayName)" -ForegroundColor Green
                        $removed++
                    } else {
                        Write-Host "Failed to remove $($appInfo.DisplayName) (Exit code: $($process.ExitCode))" -ForegroundColor Red
                        $failed++
                    }
                } elseif ($uninstallCmd -match '^"?([^"]+\.exe)"?\s*(.*)') {
                    # EXE uninstall
                    $exePath = $matches[1]
                    $arguments = $matches[2].Trim()
                    
                    if ($arguments -notmatch '(/S|/silent|/quiet|--silent)') { 
                        $arguments = "$arguments /S".Trim()
                    }
                    
                    if (Test-Path $exePath) {
                        $process = Start-Process $exePath -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                        if ($process.ExitCode -eq 0) {
                            Write-Host "Successfully removed $($appInfo.DisplayName)" -ForegroundColor Green
                            $removed++
                        } else {
                            Write-Host "Failed to remove $($appInfo.DisplayName) (Exit code: $($process.ExitCode))" -ForegroundColor Red
                            $failed++
                        }
                    } else {
                        Write-Host "Uninstaller not found for $($appInfo.DisplayName)" -ForegroundColor Red
                        $failed++
                    }
                } else {
                    Write-Host "Unknown uninstall format for $($appInfo.DisplayName)" -ForegroundColor Red
                    $failed++
                }
            }
            
        } catch {
            Write-Host "Exception removing $($appInfo.DisplayName): $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
    
    # Display results
    Write-Host "`n--- App Removal Summary ---" -ForegroundColor Cyan
    Write-Host "Successfully removed: $removed" -ForegroundColor Green
    Write-Host "Failed to remove: $failed" -ForegroundColor $(if($failed -eq 0){"Green"}else{"Yellow"})
    Write-Host "Total apps processed: $($removed + $failed)/$totalApps" -ForegroundColor White
    
    if ($removed -gt 0) {
        Write-Host "`nApp removal completed!" -ForegroundColor Green
        Write-Host "Note: Some changes may require a restart." -ForegroundColor Yellow
    }
    if ($failed -gt 0) { 
        Write-Host "`nSome apps failed to uninstall. Check the output above for details." -ForegroundColor Yellow 
    }
}

# Main execution
# If script is run directly (not called from UI_Main.ps1), provide simple command-line interface
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Path) {
    Clear-Host
    Write-Host "App Removal Tool - Command Line Mode" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Running with Administrator privileges: " -NoNewline
    Write-Host "✓ ENABLED" -ForegroundColor Green
    Write-Host ""
    Write-Host "For interactive GUI mode, please run UI_Main.ps1" -ForegroundColor Yellow
    Write-Host "This command-line mode shows all removable apps for reference." -ForegroundColor Gray
    Write-Host ""
    
    # Show available apps
    Write-Host "Loading installed applications..." -ForegroundColor Cyan
    $allApps = Get-AllInstalledApps
    
    if ($allApps.Count -gt 0) {
        Write-Host "`nFound $($allApps.Count) removable applications:" -ForegroundColor Green
        Write-Host ""
        
        $sortedApps = $allApps.Keys | Sort-Object
        $counter = 1
        foreach ($appName in $sortedApps) {
            $app = $allApps[$appName]
            Write-Host ("{0,3}. {1} ({2})" -f $counter, $appName, $app.Type) -ForegroundColor White
            $counter++
        }
        
        Write-Host ""
        Write-Host "To remove apps interactively, please use the main UI (UI_Main.ps1)" -ForegroundColor Yellow
    } else {
        Write-Host "No removable applications found." -ForegroundColor Yellow
    }
    
    Read-Host "`nPress Enter to exit"
}
