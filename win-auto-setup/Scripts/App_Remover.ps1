# Interactive App Removal Tool

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$script:SelectedApps = @(); $script:AppRegistry = @{}; $script:selectionBoxIndex = -1

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
            # Validate uninstall path accessibility
            $isValid = if ($_.UninstallString -match 'msiexec') {
                $true  # MSI products are valid if registry exists
            } elseif ($_.UninstallString -match '"?([^"]+\.exe)') {
                Test-Path $matches[1].Trim('"') -ErrorAction SilentlyContinue
            } else { $false }
            
            if ($isValid) {
                $cleanName = $_.DisplayName -replace '\s+\([^)]*\)$', ''
                $apps[$cleanName] = @{
                    UninstallString = $_.UninstallString
                    QuietUninstallString = $_.QuietUninstallString
                    DisplayName = $_.DisplayName
                    Type = "Registry"
                }
            }
        }
    }
    return $apps
}

function Get-UWPApps {
    $apps = @{}
    try {
        $allPackages = @()
        $allPackages += Get-AppxPackage -ErrorAction SilentlyContinue
        $allPackages += Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        
        $allPackages | Where-Object {
            $_.Name -notmatch '^(Microsoft\.Windows\.|Microsoft\.NET\.|Microsoft\.VCLibs|Microsoft\.UI\.Xaml|windows\.immersivecontrolpanel|Microsoft\.AAD\.BrokerPlugin|Microsoft\.AccountsControl)' -and
            $_.SignatureKind -ne "System" -and -not $_.IsFramework -and
            $_.Status -eq "Ok" -and $_.InstallLocation -and (Test-Path $_.InstallLocation -ErrorAction SilentlyContinue)
        } | Sort-Object Name -Unique | ForEach-Object {
            $displayName = if ($_.DisplayName) { $_.DisplayName } else { 
                $_.Name -replace '^Microsoft\.', '' -replace '\.', ' ' -replace 'App$', '' 
            }
            if (-not $apps.ContainsKey($displayName)) {
                $apps[$displayName] = @{
                    PackageName = $_.Name
                    PackageFullName = $_.PackageFullName
                    DisplayName = $displayName
                    Publisher = $_.Publisher
                    Type = "UWP"
                }
            }
        }
    } catch { Write-Warning "Failed to get UWP apps: $_" }
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

function Show-AppSelectionForm {
    # Initialize form components
    $form = New-Object System.Windows.Forms.Form
    $selectionBox = New-Object System.Windows.Forms.CheckedListBox 
    $checkAllBox = New-Object System.Windows.Forms.CheckBox
    $script:selectionBoxIndex = -1

    # Refresh app list
    $script:AppRegistry = Get-AllInstalledApps
    $sortedApps = $script:AppRegistry.Keys | Sort-Object
    $selectionBox.Items.AddRange($sortedApps)

    # Configure form
    $form.Text = "Interactive App Removal Tool"
    $form.ClientSize = New-Object System.Drawing.Size(500,502)
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.StartPosition = 'CenterScreen'

    # Configure instruction label
    $instructionLabel = New-Object System.Windows.Forms.Label
    $instructionLabel.Text = "Select apps to remove. Registry and UWP/Store apps included. BE CAREFUL with antivirus removal!"
    $instructionLabel.Location = New-Object System.Drawing.Point(13,5)
    $instructionLabel.Size = New-Object System.Drawing.Size(480,14)

    # Configure check all checkbox
    $checkAllBox.Location = New-Object System.Drawing.Point(16,22)
    $checkAllBox.Size = New-Object System.Drawing.Size(150,20)
    $checkAllBox.Text = 'Check/Uncheck all'
    $checkAllBox.add_CheckedChanged({
        for ($i = 0; $i -lt $selectionBox.Items.Count; $i++) {
            $selectionBox.SetItemChecked($i, $checkAllBox.Checked)
        }
    })

    # Configure selection box
    $selectionBox.Location = New-Object System.Drawing.Point(13,43)
    $selectionBox.Size = New-Object System.Drawing.Size(474,424)
    $selectionBox.add_SelectedIndexChanged({ $script:selectionBoxIndex = $selectionBox.SelectedIndex })
    $selectionBox.add_Click({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ([System.Windows.Forms.Control]::ModifierKeys -eq [System.Windows.Forms.Keys]::Shift -and $script:selectionBoxIndex -ne -1) {
                $start = [math]::Min($script:selectionBoxIndex, $selectionBox.SelectedIndex)
                $end = [math]::Max($script:selectionBoxIndex, $selectionBox.SelectedIndex)
                $checkState = $selectionBox.GetItemChecked($script:selectionBoxIndex)
                for ($i = $start; $i -le $end; $i++) {
                    $selectionBox.SetItemChecked($i, $checkState)
                }
            } elseif ($script:selectionBoxIndex -ne $selectionBox.SelectedIndex) {
                $selectionBox.SetItemChecked($selectionBox.SelectedIndex, -not $selectionBox.GetItemChecked($selectionBox.SelectedIndex))
            }
        }
    })

    # Configure buttons
    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Text = "Remove Selected Apps"
    $removeButton.Location = New-Object System.Drawing.Point(27,472)
    $removeButton.Size = New-Object System.Drawing.Size(140,23)
    $removeButton.add_Click({
        $script:SelectedApps = $selectionBox.CheckedItems
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(180,472)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.add_Click({ $form.Close() })

    # Add controls to form
    $form.Controls.AddRange(@($removeButton, $cancelButton, $instructionLabel, $checkAllBox, $selectionBox))
    $form.Add_Shown({ $form.Activate(); $selectionBox.Focus() })
    
    return $form.ShowDialog()
}

function Remove-SelectedApps {
    param ([array]$AppsList)
    
    $removed = $failed = 0
    $totalApps = $AppsList.Count
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    Write-Host "`nStarting app removal..." -ForegroundColor Cyan

    for ($i = 0; $i -lt $totalApps; $i++) { 
        $app = $AppsList[$i]
        $appInfo = $script:AppRegistry[$app]
        Write-Host "`rProcessing ($($i+1)/$totalApps): $($appInfo.DisplayName)" -NoNewline -ForegroundColor Cyan
        
        try {
            $success = $false
            
            if ($appInfo.Type -eq "UWP") {
                # Remove UWP app
                try {
                    Remove-AppxPackage -Package $appInfo.PackageFullName -ErrorAction Stop
                    $success = $true
                } catch {
                    Remove-AppxPackage -Package $appInfo.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                    Get-AppxPackage -Name $appInfo.PackageName -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                    $success = $true
                }
                
                # Clean provisioned packages
                if ($success) {
                    Get-AppxProvisionedPackage -Online | Where-Object { 
                        $_.DisplayName -eq $app -or $_.PackageName -like "*$($appInfo.PackageName)*" 
                    } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                }
            } else {
                # Remove registry app
                $uninstallCmd = if ($appInfo.QuietUninstallString) { $appInfo.QuietUninstallString } else { $appInfo.UninstallString }
                
                if ($uninstallCmd -match 'msiexec.*(/I|/X)\s*(\{[^}]+\})') {
                    $productCode = $matches[2]
                    $process = Start-Process "msiexec.exe" -ArgumentList "/X$productCode /quiet /norestart" -Wait -PassThru -WindowStyle Hidden
                    $success = ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1605)
                    
                    # Clean MSI registry entries
                    if ($success) {
                        $cleanupPaths = @(
                            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\*\Products\$($productCode.Replace('-','').Replace('{','').Replace('}',''))",
                            "HKLM:\SOFTWARE\Classes\Installer\Products\$($productCode.Replace('-','').Replace('{','').Replace('}',''))"
                        )
                        $cleanupPaths | ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }
                    }
                } elseif ($uninstallCmd -match '^"?([^"]+\.exe)"?\s*(.*)') {
                    $exePath = $matches[1]
                    $arguments = $matches[2]
                    if ($arguments -notmatch '(/S|/silent|/quiet|--silent)') { $arguments += " /S" }
                    
                    if (Test-Path $exePath) {
                        $process = Start-Process $exePath -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                        $success = ($process.ExitCode -eq 0)
                    }
                }
            }
            
            # Clean registry entries for all successful removals
            if ($success) {
                $removed++
                foreach ($regPath in $registryPaths) {
                    Get-ChildItem $regPath -ErrorAction SilentlyContinue | Where-Object {
                        ($_.GetValue('DisplayName') -eq $appInfo.DisplayName) -or 
                        ($_.PSChildName -eq $app) -or
                        ($_.GetValue('DisplayName') -like "*$app*")
                    } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
            } else {
                $failed++
            }
        } catch { 
            $failed++
        }
    }

    # Display results
    Write-Host "`r$(' ' * 80)"
    Write-Host "`n--- App Removal Summary ---" -ForegroundColor Cyan
    Write-Host "Successfully removed: $removed" -ForegroundColor Green
    Write-Host "Failed or skipped: $failed" -ForegroundColor $(if($failed -eq 0){"Green"}else{"Yellow"})
    Write-Host "Total apps: $totalApps" -ForegroundColor White
    
    if ($removed -gt 0) {
        Write-Host "`nApp removal completed!" -ForegroundColor Green
        Write-Host "Note: Some changes may require a restart." -ForegroundColor Yellow
    }
    if ($failed -gt 0) { 
        Write-Host "`nSome apps may have required user interaction." -ForegroundColor Yellow 
    }
}

# Main execution
Clear-Host
Write-Host "Interactive App Removal Tool" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

$result = Show-AppSelectionForm

if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $script:SelectedApps.Count -gt 0) {
    Write-Host "`nApps selected for removal:" -ForegroundColor Cyan
    $script:SelectedApps | ForEach-Object { 
        Write-Host "  - $($script:AppRegistry[$_].DisplayName)" -ForegroundColor White 
    }
    
    $confirm = Read-Host "`nRemove these $($script:SelectedApps.Count) apps? (Y/N)"
    if ($confirm -match '^[Yy]') {
        Remove-SelectedApps -AppsList $script:SelectedApps
    } else {
        Write-Host "Cancelled." -ForegroundColor Yellow
    }
} elseif ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`nNo apps selected." -ForegroundColor Yellow
} else {
    Write-Host "`nCancelled." -ForegroundColor Yellow
}

Read-Host "`nPress Enter to exit"
