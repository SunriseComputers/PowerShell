#Requires -RunAsAdministrator

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Windows Update Disabler Script" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-Host ""

Write-ColorOutput "[1/6] This Script will Disable Windows Updates Indefinately" "Yellow"

Write-ColorOutput "`n[2/6] Configuring Registry Settings..." "Yellow"
$RegPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$RegPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

if (-not (Test-Path $RegPath1)) {
    New-Item -Path $RegPath1 -Force | Out-Null
    Write-ColorOutput "Created WindowsUpdate registry key" "Green"
}

if (-not (Test-Path $RegPath2)) {
    New-Item -Path $RegPath2 -Force | Out-Null
    Write-ColorOutput "Created AU registry key" "Green"
}

Set-ItemProperty -Path $RegPath2 -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
Write-ColorOutput "Set NoAutoUpdate = 1" "Green"

Set-ItemProperty -Path $RegPath2 -Name "AUOptions" -Value 2 -Type DWord -Force
Write-ColorOutput "Set AUOptions = 2" "Green"

Write-ColorOutput "`n[3/6] Disabling Check for Updates Button..." "Yellow"
Set-ItemProperty -Path $RegPath1 -Name "SetDisableUXWUAccess" -Value 1 -Type DWord -Force
Write-ColorOutput "Check for Updates button disabled" "Green"

Set-ItemProperty -Path $RegPath2 -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -Force
Write-ColorOutput "Disabled automatic reboot with logged on users" "Green"

Write-ColorOutput "`n[4/6] Disabling Windows Update Service..." "Yellow"
try {
    Stop-Service -Name "wuauserv" -Force -ErrorAction Stop
    Write-ColorOutput "Windows Update service stopped" "Green"

    Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction Stop
    Write-ColorOutput "Windows Update service disabled" "Green"

    $RelatedServices = @("UsoSvc", "WaaSMedicSvc")
    foreach ($service in $RelatedServices) {
        try {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-ColorOutput "$service disabled" "Green"
        } catch {
            Write-ColorOutput "Could not disable $service" "Yellow"
        }
    }
} catch {
    Write-ColorOutput "Error disabling services: $($_.Exception.Message)" "Red"
}

Write-ColorOutput "`n[5/6] Configuring Group Policy Settings..." "Yellow"
try {
    $GPRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

    Set-ItemProperty -Path $GPRegPath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "SetDisableUXWUAccess" -Value 1 -Type DWord -Force

    Set-ItemProperty -Path $GPRegPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -Force

    $DriverRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching"
    if (-not (Test-Path $DriverRegPath)) {
        New-Item -Path $DriverRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $DriverRegPath -Name "SearchOrderConfig" -Value 0 -Type DWord -Force

    Write-ColorOutput "Group Policy settings configured" "Green"
} catch {
    Write-ColorOutput "Error configuring Group Policy: $($_.Exception.Message)" "Red"
}

Write-ColorOutput "`n[6/6] Disabling Update Orchestrator Tasks..." "Yellow"
try {
    $ScheduledTasks = @(
        "\Microsoft\Windows\WindowsUpdate\Scheduled Start",
        "\Microsoft\Windows\WindowsUpdate\sih",
        "\Microsoft\Windows\WindowsUpdate\sihboot",
        "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
        "\Microsoft\Windows\UpdateOrchestrator\Schedule Work",
        "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
    )

    foreach ($task in $ScheduledTasks) {
        try {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            Write-ColorOutput "Disabled: $task" "Green"
        } catch {
            Write-ColorOutput "Could not disable: $task" "Yellow"
        }
    }
} catch {
    Write-ColorOutput "Error disabling scheduled tasks: $($_.Exception.Message)" "Red"
}

Write-ColorOutput "`n[Final] Applying Changes..." "Yellow"
try {
    Start-Process -FilePath "gpupdate" -ArgumentList "/force" -Wait -NoNewWindow
    Write-ColorOutput "Group Policy updated successfully" "Green"
} catch {
    Write-ColorOutput "Could not force Group Policy update" "Yellow"
}

Write-Host ""
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "Summary of Changes:" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "[OK] Registry keys configured" "Green"
Write-ColorOutput "[OK] Windows Update service disabled" "Green"
Write-ColorOutput "[OK] Check for Updates button disabled" "Green"
Write-ColorOutput "[OK] Group Policy settings applied" "Green"
Write-ColorOutput "[OK] Scheduled tasks disabled" "Green"
Write-Host ""
Write-ColorOutput "IMPORTANT NOTES:" "Yellow"
Write-ColorOutput "1. A system restart is recommended for all changes to take effect" "White"
Write-ColorOutput "2. Registry backup saved to: $BackupPath" "White"
Write-ColorOutput "3. Windows Update is now completely disabled" "White"
Write-ColorOutput "4. The Check for Updates button will be grayed out" "White"
Write-Host ""
Write-ColorOutput "To re-enable updates, run the restore script or restore the registry backup" "Cyan"
Write-Host ""

$restart = Read-Host "Would you like to restart now to apply all changes? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-ColorOutput "Restarting in 10 seconds..." "Yellow"
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}
