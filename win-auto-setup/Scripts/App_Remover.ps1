# Interactive App Removal Tool - Registry Based
# Modern version using Windows Registry for app discovery

# Ensure we're running as admin
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "This script needs to be run as Administrator. Attempting to relaunch..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Load Windows Forms assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables
$script:SelectedApps = @()
$script:AppRegistry = @{}
$script:selectionBoxIndex = -1

# Get installed apps from registry
function Get-InstalledApps {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    $apps = @{}
    foreach ($path in $registryPaths) {
        try {
            Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -and 
                $_.DisplayName -notmatch '^(Microsoft Visual C\+\+|Microsoft \.NET|Update for|Security Update|Hotfix|KB\d+)' -and
                $_.UninstallString -and
                $_.SystemComponent -ne 1 -and
                $_.ReleaseType -ne "Security Update" -and
                $_.ParentKeyName -eq $null
            } | ForEach-Object {
                $displayText = if ($_.Publisher) { "$($_.DisplayName) ($($_.Publisher))" } else { $_.DisplayName }
                $apps[$displayText] = @{
                    UninstallString = $_.UninstallString
                    QuietUninstallString = $_.QuietUninstallString
                    DisplayName = $_.DisplayName
                    Publisher = $_.Publisher
                }
            }
        } catch { }
    }
    return $apps
}

# Shows application selection form
function Show-AppSelectionForm {
    # Initialize form and controls
    $form = New-Object System.Windows.Forms.Form
    $selectionBox = New-Object System.Windows.Forms.CheckedListBox 
    $loadingLabel = New-Object System.Windows.Forms.Label
    $checkUncheckCheckBox = New-Object System.Windows.Forms.CheckBox
    
    $script:selectionBoxIndex = -1

    # Event handlers
    $handler_saveButton_Click = {
        $script:SelectedApps = $selectionBox.CheckedItems
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }

    $handler_cancelButton_Click = { $form.Close() }
    $selectionBox_SelectedIndexChanged = { $script:selectionBoxIndex = $selectionBox.SelectedIndex }

    $selectionBox_MouseDown = {
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and [System.Windows.Forms.Control]::ModifierKeys -eq [System.Windows.Forms.Keys]::Shift -and $script:selectionBoxIndex -ne -1) {
            $topIndex = $script:selectionBoxIndex
            $start = [math]::Min($topIndex, $selectionBox.SelectedIndex)
            $end = [math]::Max($topIndex, $selectionBox.SelectedIndex)
            for ($i = $start; $i -le $end; $i++) {
                $selectionBox.SetItemChecked($i, $selectionBox.GetItemChecked($topIndex))
            }
        } elseif ($script:selectionBoxIndex -ne $selectionBox.SelectedIndex) {
            $selectionBox.SetItemChecked($selectionBox.SelectedIndex, -not $selectionBox.GetItemChecked($selectionBox.SelectedIndex))
        }
    }

    $check_All = {
        for ($i = 0; $i -lt $selectionBox.Items.Count; $i++) {
            $selectionBox.SetItemChecked($i, $checkUncheckCheckBox.Checked)
        }
    }

    # Load apps into the selection box
    $load_Apps = {
        $form.WindowState = $form.WindowState
        $script:selectionBoxIndex = -1
        $checkUncheckCheckBox.Checked = $False
        $loadingLabel.Visible = $true
        $form.Refresh()
        $selectionBox.Items.Clear()

        # Get apps from registry
        $script:AppRegistry = Get-InstalledApps
        
        # Add apps to selection box (sorted)
        $script:AppRegistry.Keys | Sort-Object | ForEach-Object {
            $selectionBox.Items.Add($_, $false) | Out-Null
        }
        
        $loadingLabel.Visible = $False
    }

    # Configure form and controls
    $form.Text = "Interactive App Removal Tool"
    $form.ClientSize = New-Object System.Drawing.Size(500,502)
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $False
    $form.StartPosition = 'CenterScreen'

    # Create buttons and labels
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = "Remove Selected Apps"
    $saveButton.Location = New-Object System.Drawing.Point(27,472)
    $saveButton.Size = New-Object System.Drawing.Size(140,23)
    $saveButton.add_Click($handler_saveButton_Click)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(180,472)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.add_Click($handler_cancelButton_Click)

    $instructionLabel = New-Object System.Windows.Forms.Label
    $instructionLabel.Text = "Select apps to remove. Apps are loaded from Windows Registry."
    $instructionLabel.Location = New-Object System.Drawing.Point(13,5)
    $instructionLabel.Size = New-Object System.Drawing.Size(480,14)

    $loadingLabel.Location = New-Object System.Drawing.Point(16,46)
    $loadingLabel.Size = New-Object System.Drawing.Size(400,418)
    $loadingLabel.Text = 'Loading installed apps from registry...'
    $loadingLabel.BackColor = "White"
    $loadingLabel.Visible = $false

    $checkUncheckCheckBox.Location = New-Object System.Drawing.Point(16,22)
    $checkUncheckCheckBox.Size = New-Object System.Drawing.Size(150,20)
    $checkUncheckCheckBox.Text = 'Check/Uncheck all'
    $checkUncheckCheckBox.add_CheckedChanged($check_All)

    $selectionBox.Location = New-Object System.Drawing.Point(13,43)
    $selectionBox.Size = New-Object System.Drawing.Size(474,424)
    $selectionBox.add_SelectedIndexChanged($selectionBox_SelectedIndexChanged)
    $selectionBox.add_Click($selectionBox_MouseDown)

    $form.Controls.AddRange(@($saveButton, $cancelButton, $instructionLabel, $loadingLabel, $checkUncheckCheckBox, $selectionBox))
    $form.add_Load($load_Apps)
    $form.Add_Shown({$form.Activate(); $selectionBox.Focus()})

    return $form.ShowDialog()
}

# Function to remove selected apps
function Remove-SelectedApps {
    param ([array]$AppsList)

    $removed = 0
    $failed = 0
    $currentApp = 0
    $totalApps = $AppsList.Count

    Write-Host "`nStarting app removal process..." -ForegroundColor Cyan
    Write-Host ""

    foreach ($app in $AppsList) { 
        $currentApp++
        $appInfo = $script:AppRegistry[$app]
        
        Write-Host "`rProcessing ($currentApp/$totalApps): $($appInfo.DisplayName)                    " -NoNewline -ForegroundColor Cyan
        
        $appRemoved = $false

        try {
            # Try quiet uninstall first, then regular uninstall
            $uninstallCmd = if ($appInfo.QuietUninstallString) { $appInfo.QuietUninstallString } else { $appInfo.UninstallString }
            
            # Handle different uninstaller types
            if ($uninstallCmd -match 'msiexec.*(/I|/X)\s*(\{[^}]+\})') {
                # MSI package - use msiexec with silent flags
                $productCode = $matches[2]
                $process = Start-Process "msiexec.exe" -ArgumentList "/X$productCode /quiet /norestart" -Wait -PassThru -WindowStyle Hidden
                $appRemoved = ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1605) # 1605 = product not found (already removed)
            }
            elseif ($uninstallCmd -match '^"?([^"]+\.exe)"?\s*(.*)') {
                # Regular executable
                $exePath = $matches[1]
                $args = $matches[2]
                
                # Add common silent flags if not present
                if ($args -notmatch '(/S|/silent|/quiet|--silent)') {
                    $args += " /S"
                }
                
                if (Test-Path $exePath) {
                    $process = Start-Process $exePath -ArgumentList $args -Wait -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                    $appRemoved = ($process.ExitCode -eq 0)
                }
            }

            if ($appRemoved) { $removed++ } else { $failed++ }
        } 
        catch { 
            $failed++ 
        }
    }

    # Clear progress and show summary
    Write-Host "`r                                                                                " -NoNewline
    Write-Host "`r" -NoNewline
    Write-Host "`n--- App Removal Summary ---" -ForegroundColor Cyan
    Write-Host "Successfully removed: $removed" -ForegroundColor Green
    Write-Host "Failed or skipped: $failed" -ForegroundColor $(if($failed -eq 0){"Green"}else{"Yellow"})
    Write-Host "Total apps: $totalApps" -ForegroundColor White
    
    if ($removed -gt 0) {
        Write-Host "`nApp removal completed!" -ForegroundColor Green
        Write-Host "Note: Some changes may require a system restart to take effect." -ForegroundColor Yellow
    }
    if ($failed -gt 0) {
        Write-Host "`nSome apps may have required user interaction or custom uninstall procedures." -ForegroundColor Yellow
    }
}

# Main execution
Clear-Host
Write-Host "Interactive App Removal Tool - Registry Based" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "`nOpening interactive app selection window..." -ForegroundColor Green

# Show the interactive form
$result = Show-AppSelectionForm

if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $script:SelectedApps.Count -gt 0) {
    Write-Host "`nApps selected for removal:" -ForegroundColor Cyan
    foreach ($app in $script:SelectedApps) {
        Write-Host "  - $($script:AppRegistry[$app].DisplayName)" -ForegroundColor White
    }
    
    $confirm = Read-Host "`nDo you want to proceed with removing these $($script:SelectedApps.Count) apps? (Y/N)"
    
    if ($confirm -match '^[Yy]') {
        Remove-SelectedApps -AppsList $script:SelectedApps
    } else {
        Write-Host "App removal cancelled by user." -ForegroundColor Yellow
    }
} elseif ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`nNo apps were selected for removal." -ForegroundColor Yellow
} else {
    Write-Host "`nApp selection cancelled by user." -ForegroundColor Yellow
}

Write-Host "`nPress Enter to exit..."
Read-Host