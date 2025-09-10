# Interactive App Removal Tool

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$script:SelectedApps = @(); $script:AppRegistry = @{}; $script:selectionBoxIndex = -1

function Get-InstalledApps {
    $apps = @{}
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
      "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
      "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*") | ForEach-Object {
        Get-ItemProperty $_ -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -and $_.UninstallString -and $_.SystemComponent -ne 1 -and
            $_.DisplayName -notmatch '^(Microsoft Visual C\+\+|Microsoft \.NET|Update for|Security Update|Hotfix|KB\d+)' -and
            $_.ReleaseType -ne "Security Update" -and $_.ParentKeyName -eq $null
        } | ForEach-Object {
            $cleanName = $_.DisplayName -replace '\s+\([^)]*\)$', ''
            $apps[$cleanName] = @{ UninstallString = $_.UninstallString; QuietUninstallString = $_.QuietUninstallString; DisplayName = $_.DisplayName; Type = "Registry" }
        }
    }
    return $apps
}

function Get-UWPApps {
    $apps = @{}
    try {
        $packages = Get-AppxPackage -ErrorAction SilentlyContinue; $packages += Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        $packages | Where-Object {
            $_.Name -notmatch '^(Microsoft\.Windows\.|Microsoft\.NET\.|Microsoft\.VCLibs|Microsoft\.UI\.Xaml|windows\.immersivecontrolpanel|Microsoft\.AAD\.BrokerPlugin|Microsoft\.AccountsControl)' -and
            $_.SignatureKind -ne "System" -and $_.IsFramework -eq $false
        } | Sort-Object Name -Unique | ForEach-Object {
            $simpleName = if ($_.DisplayName) { $_.DisplayName } else { $_.Name -replace '^Microsoft\.', '' -replace '\.', ' ' -replace 'App$', '' }
            if (-not $apps.ContainsKey($simpleName)) {
                $apps[$simpleName] = @{ PackageName = $_.Name; PackageFullName = $_.PackageFullName; DisplayName = $simpleName; Publisher = $_.Publisher; Type = "UWP" }
            }
        }
    } catch { }
    return $apps
}

function Get-BloatwareApps {
    $bloatwareNames = @('Clipchamp', 'Maps', 'Xbox', 'Xbox Game Bar', 'Xbox Identity Provider', 'Xbox Speech To Text Overlay',
        'Microsoft Teams', 'Teams', 'OneDrive', 'Microsoft To Do', 'Microsoft Sticky Notes', 'Alarms & Clock', 'Calculator',
        'Calendar', 'Camera', 'Get Help', 'Groove Music', 'Mail and Calendar', 'Movies & TV', 'News', 'OneNote', 'Paint 3D',
        'Photos', 'Skype', 'Solitaire', 'Sports', 'Voice Recorder', 'Weather', 'Microsoft Store', 'Microsoft Edge', 'Cortana',
        'Mixed Reality Portal', 'Phone Link', 'Quick Assist', 'Snipping Tool', 'Tips', 'Whiteboard', 'Microsoft Advertising SDK', 'Microsoft Pay')
    
    $allApps = Get-AllInstalledApps; $bloatware = @{}; $regular = @{}
    
    foreach ($appName in $allApps.Keys) {
        $isBloatware = $false
        foreach ($bloatName in $bloatwareNames) {
            if ($appName -like "*$bloatName*" -or $appName -eq $bloatName) { $isBloatware = $true; break }
        }
        if ($isBloatware -or $allApps[$appName].Type -eq "UWP") { $bloatware[$appName] = $allApps[$appName] } else { $regular[$appName] = $allApps[$appName] }
    }
    return @{ Bloatware = $bloatware; Regular = $regular }
}

function Get-AllInstalledApps {
    $allApps = Get-InstalledApps; $uwpApps = Get-UWPApps
    foreach ($key in $uwpApps.Keys) { $allApps[$key] = $uwpApps[$key] }
    return $allApps
}

function Show-AppSelectionForm {
    $form = New-Object System.Windows.Forms.Form
    $selectionBox = New-Object System.Windows.Forms.CheckedListBox 
    $loadingLabel = New-Object System.Windows.Forms.Label
    $checkUncheckCheckBox = New-Object System.Windows.Forms.CheckBox
    $script:selectionBoxIndex = -1

    # Event handlers
    $saveButton_Click = {
        $script:SelectedApps = @()
        foreach ($item in $selectionBox.CheckedItems) {
            # Skip header lines (section dividers)
            $itemText = $item.ToString()
            if (-not ($itemText.StartsWith("═══") -or $itemText.Contains("BLOATWARE APP LIST") -or $itemText.Contains("OTHER INSTALLED APPS"))) {
                $script:SelectedApps += $item
            }
        }
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }

    $selectionBox_SelectedIndexChanged = { $script:selectionBoxIndex = $selectionBox.SelectedIndex }

    $selectionBox_MouseDown = {
        if ($selectionBox.SelectedIndex -ge 0) {
            $selectedText = $selectionBox.Items[$selectionBox.SelectedIndex].ToString()
            if ($selectedText.StartsWith("═══") -or $selectedText.Contains("BLOATWARE APP LIST") -or $selectedText.Contains("OTHER INSTALLED APPS")) { return }
        }
        
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and [System.Windows.Forms.Control]::ModifierKeys -eq [System.Windows.Forms.Keys]::Shift -and $script:selectionBoxIndex -ne -1) {
            $topIndex = $script:selectionBoxIndex; $start = [math]::Min($topIndex, $selectionBox.SelectedIndex); $end = [math]::Max($topIndex, $selectionBox.SelectedIndex)
            for ($i = $start; $i -le $end; $i++) {
                $itemText = $selectionBox.Items[$i].ToString()
                if (-not ($itemText.StartsWith("═══") -or $itemText.Contains("BLOATWARE APP LIST") -or $itemText.Contains("OTHER INSTALLED APPS"))) {
                    $selectionBox.SetItemChecked($i, $selectionBox.GetItemChecked($topIndex))
                }
            }
        } elseif ($script:selectionBoxIndex -ne $selectionBox.SelectedIndex) {
            $selectionBox.SetItemChecked($selectionBox.SelectedIndex, -not $selectionBox.GetItemChecked($selectionBox.SelectedIndex))
        }
    }

    $check_All = {
        for ($i = 0; $i -lt $selectionBox.Items.Count; $i++) {
            $itemText = $selectionBox.Items[$i].ToString()
            if (-not ($itemText.StartsWith("═══") -or $itemText.Contains("BLOATWARE APP LIST") -or $itemText.Contains("OTHER INSTALLED APPS"))) {
                $selectionBox.SetItemChecked($i, $checkUncheckCheckBox.Checked)
            }
        }
    }

    $load_Apps = {
        $script:selectionBoxIndex = -1; $checkUncheckCheckBox.Checked = $false; $loadingLabel.Visible = $true; $form.Refresh(); $selectionBox.Items.Clear()
        $categorizedApps = Get-BloatwareApps; $script:AppRegistry = @{}
        
        if ($categorizedApps.Bloatware.Count -gt 0) {
            $selectionBox.Items.Add("═══════════════════════════════════════", $false) | Out-Null
            $selectionBox.Items.Add("         1. BLOATWARE APP LIST", $false) | Out-Null
            $selectionBox.Items.Add("═══════════════════════════════════════", $false) | Out-Null
            $categorizedApps.Bloatware.Keys | Sort-Object | ForEach-Object { 
                $selectionBox.Items.Add($_, $false) | Out-Null; $script:AppRegistry[$_] = $categorizedApps.Bloatware[$_]
            }
        }
        
        if ($categorizedApps.Regular.Count -gt 0) {
            $selectionBox.Items.Add("═══════════════════════════════════════", $false) | Out-Null
            $selectionBox.Items.Add("      2. OTHER INSTALLED APPS", $false) | Out-Null
            $selectionBox.Items.Add("═══════════════════════════════════════", $false) | Out-Null
            $categorizedApps.Regular.Keys | Sort-Object | ForEach-Object { 
                $selectionBox.Items.Add($_, $false) | Out-Null; $script:AppRegistry[$_] = $categorizedApps.Regular[$_]
            }
        }
        $loadingLabel.Visible = $false
    }

    $form.Text = "Interactive App Removal Tool"; $form.ClientSize = New-Object System.Drawing.Size(500,502)
    $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false; $form.StartPosition = 'CenterScreen'

    $saveButton = New-Object System.Windows.Forms.Button; $saveButton.Text = "Remove Selected Apps"
    $saveButton.Location = New-Object System.Drawing.Point(27,472); $saveButton.Size = New-Object System.Drawing.Size(140,23)
    $saveButton.add_Click($saveButton_Click)

    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(180,472); $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $cancelButton.add_Click({ $form.Close() })

    $instructionLabel = New-Object System.Windows.Forms.Label; $instructionLabel.Text = "Select apps to remove. Registry and UWP/Store apps included."
    $instructionLabel.Location = New-Object System.Drawing.Point(13,5); $instructionLabel.Size = New-Object System.Drawing.Size(480,14)

    $loadingLabel.Location = New-Object System.Drawing.Point(16,46); $loadingLabel.Size = New-Object System.Drawing.Size(400,418)
    $loadingLabel.Text = 'Loading apps...'; $loadingLabel.BackColor = "White"; $loadingLabel.Visible = $false

    $checkUncheckCheckBox.Location = New-Object System.Drawing.Point(16,22); $checkUncheckCheckBox.Size = New-Object System.Drawing.Size(150,20)
    $checkUncheckCheckBox.Text = 'Check/Uncheck all'; $checkUncheckCheckBox.add_CheckedChanged($check_All)

    $selectionBox.Location = New-Object System.Drawing.Point(13,43); $selectionBox.Size = New-Object System.Drawing.Size(474,424)
    $selectionBox.add_SelectedIndexChanged($selectionBox_SelectedIndexChanged); $selectionBox.add_Click($selectionBox_MouseDown)

    $form.Controls.AddRange(@($saveButton, $cancelButton, $instructionLabel, $loadingLabel, $checkUncheckCheckBox, $selectionBox))
    $form.add_Load($load_Apps); $form.Add_Shown({$form.Activate(); $selectionBox.Focus()})
    return $form.ShowDialog()
}

function Remove-SelectedApps {
    param ([array]$AppsList)
    $removed = $failed = $currentApp = 0
    $totalApps = $AppsList.Count

    Write-Host "`nStarting app removal..." -ForegroundColor Cyan

    foreach ($app in $AppsList) { 
        $currentApp++
        $appInfo = $script:AppRegistry[$app]
        Write-Host "`rProcessing ($currentApp/$totalApps): $($appInfo.DisplayName)                    " -NoNewline -ForegroundColor Cyan
        
        $appRemoved = $false
        try {
            if ($appInfo.Type -eq "UWP") {
                try {
                    Remove-AppxPackage -Package $appInfo.PackageFullName -ErrorAction Stop
                    $appRemoved = $true
                } catch {
                    try {
                        Remove-AppxPackage -Package $appInfo.PackageFullName -AllUsers -ErrorAction Stop
                        $appRemoved = $true
                    } catch {
                        Get-AppxPackage -Name $appInfo.PackageName | Remove-AppxPackage -ErrorAction SilentlyContinue
                        Get-AppxPackage -Name $appInfo.PackageName -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                        $appRemoved = $true
                    }
                }
            } else {
                $uninstallCmd = if ($appInfo.QuietUninstallString) { $appInfo.QuietUninstallString } else { $appInfo.UninstallString }
                
                if ($uninstallCmd -match 'msiexec.*(/I|/X)\s*(\{[^}]+\})') {
                    $productCode = $matches[2]; $process = Start-Process "msiexec.exe" -ArgumentList "/X$productCode /quiet /norestart" -Wait -PassThru -WindowStyle Hidden
                    $appRemoved = ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1605)
                } elseif ($uninstallCmd -match '^"?([^"]+\.exe)"?\s*(.*)') {
                    $exePath = $matches[1]; $args = $matches[2]
                    if ($args -notmatch '(/S|/silent|/quiet|--silent)') { $args += " /S" }
                    if (Test-Path $exePath) {
                        $process = Start-Process $exePath -ArgumentList $args -Wait -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                        $appRemoved = ($process.ExitCode -eq 0)
                    }
                }
            }
            if ($appRemoved) { $removed++ } else { $failed++ }
        } catch { $failed++ }
    }

    Write-Host "`r                                                                                "
    Write-Host "`n--- App Removal Summary ---" -ForegroundColor Cyan
    Write-Host "Successfully removed: $removed" -ForegroundColor Green
    Write-Host "Failed or skipped: $failed" -ForegroundColor $(if($failed -eq 0){"Green"}else{"Yellow"})
    Write-Host "Total apps: $totalApps" -ForegroundColor White
    
    if ($removed -gt 0) {
        Write-Host "`nApp removal completed!" -ForegroundColor Green
        Write-Host "Note: Some changes may require a restart." -ForegroundColor Yellow
    }
    if ($failed -gt 0) { Write-Host "`nSome apps may have required user interaction." -ForegroundColor Yellow }
}

# Main execution
Clear-Host
Write-Host "Interactive App Removal Tool" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

$result = Show-AppSelectionForm

if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $script:SelectedApps.Count -gt 0) {
    Write-Host "`nApps selected for removal:" -ForegroundColor Cyan
    foreach ($app in $script:SelectedApps) { Write-Host "  - $($script:AppRegistry[$app].DisplayName)" -ForegroundColor White }
    
    $confirm = Read-Host "`nRemove these $($script:SelectedApps.Count) apps? (Y/N)"
    if ($confirm -match '^[Yy]') { Remove-SelectedApps -AppsList $script:SelectedApps } else { Write-Host "Cancelled." -ForegroundColor Yellow }
} elseif ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`nNo apps selected." -ForegroundColor Yellow
} else {
    Write-Host "`nCancelled." -ForegroundColor Yellow
}

Read-Host "`nPress Enter to exit"
