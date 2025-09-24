#Requires -RunAsAdministrator

# Load the tweaks configuration
$tweaksConfig = @'
  "DisableSnapAssistFlyout": {
    "Content": "Disable Snap Assist Flyout",
    "Description": "Turns off the Snap Assist Flyout feature in Windows.",
    "category": "Performance",
    "registry": [
      {
        "Path": "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
        "Name": "SnapAssistFlyoutEnabled",
        "Type": "DWord",
        "Value": "0"
      }
    ]
  },
{
  "DeleteTempFiles": {
    "Content": "Delete Temporary Files",
    "Description": "Deletes temporary files to free up disk space.",
    "category": "Cleanup",
    "InvokeScript": [
      "Get-ChildItem -Path $env:TEMP -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue",
      "Get-ChildItem -Path 'C:\\Windows\\Temp' -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue",
      "Get-ChildItem -Path 'C:\\Windows\\Prefetch' -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue"
    ]
  },
  "DisableConsumerFeatures": {
    "Content": "Disable ConsumerFeatures",
    "Description": "Disables Windows consumer features and app suggestions.",
    "category": "Privacy",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
        "Name": "DisableWindowsConsumerFeatures",
        "Type": "DWord",
        "Value": "1"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "Name": "ContentDeliveryAllowed",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "Name": "SilentInstalledAppsEnabled",
        "Type": "DWord",
        "Value": "0"
      }
    ]
  },
  "DisableTelemetry": {
    "Content": "Disable Telemetry",
    "Description": "Disables Windows telemetry and data collection.",
    "category": "Privacy",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection",
        "Name": "AllowTelemetry",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
        "Name": "AllowTelemetry",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection",
        "Name": "MaxTelemetryAllowed",
        "Type": "DWord",
        "Value": "0"
      }
    ],
    "ScheduledTask": [
      {
        "Name": "Microsoft\\Windows\\Application Experience\\Microsoft Compatibility Appraiser",
        "State": "Disabled"
      },
      {
        "Name": "Microsoft\\Windows\\Customer Experience Improvement Program\\Consolidator",
        "State": "Disabled"
      }
    ]
  },
  "DisableActivityHistory": {
    "Content": "Disable Activity History",
    "Description": "This erases recent docs, clipboard, and run history.",
    "category": "Privacy",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "Name": "EnableActivityFeed",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "Name": "PublishUserActivities",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "Name": "UploadUserActivities",
        "Type": "DWord",
        "Value": "0"
      }
    ]
  },
  "DisableExplorerAutoDiscovery": {
    "Content": "Disable Explorer Automatic Folder Discovery",
    "Description": "Disables automatic folder type discovery in File Explorer.",
    "category": "Performance",
    "registry": [
      {
        "Path": "HKCU:\\SOFTWARE\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\\AllFolders\\Shell",
        "Name": "FolderType",
        "Type": "String",
        "Value": "NotSpecified"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
        "Name": "NoRecentDocsHistory",
        "Type": "DWord",
        "Value": "1"
      }
    ]
  },
  "DisableGameDVR": {
    "Content": "Disable GameDVR",
    "Description": "Disables Windows Game DVR and Game Mode features.",
    "category": "Performance",
    "registry": [
      {
        "Path": "HKCU:\\System\\GameConfigStore",
        "Name": "GameDVR_Enabled",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR",
        "Name": "AllowGameDVR",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\GameDVR",
        "Name": "AppCaptureEnabled",
        "Type": "DWord",
        "Value": "0"
      }
    ]
  },
  "DisableHomegroup": {
    "Content": "Disable Homegroup",
    "Description": "Disables HomeGroup networking service.",
    "category": "Privacy",
    "service": [
      {
        "Name": "HomeGroupListener",
        "StartupType": "Disabled"
      },
      {
        "Name": "HomeGroupProvider",
        "StartupType": "Disabled"
      }
    ]
  },
  "DisableLocationTracking": {
    "Content": "Disable Location Tracking",
    "Description": "Disables Windows location tracking and related services.",
    "category": "Privacy",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\location",
        "Name": "Value",
        "Type": "String",
        "Value": "Deny"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Sensor\\Overrides\\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}",
        "Name": "SensorPermissionState",
        "Type": "DWord",
        "Value": "0"
      }
    ],
    "service": [
      {
        "Name": "lfsvc",
        "StartupType": "Disabled"
      }
    ]
  },
  "DisableStorageSense": {
    "Content": "Disable Storage Sense",
    "Description": "Disables automatic disk cleanup and storage management.",
    "category": "Performance",
    "registry": [
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\StorageSense\\Parameters\\StoragePolicy",
        "Name": "01",
        "Type": "DWord",
        "Value": "0"
      }
    ]
  },
  "DisableWiFiSense": {
    "Content": "Disable Wi-Fi Sense",
    "Description": "Disables WiFi sense and password sharing features.",
    "category": "Privacy",
    "registry": [
      {
        "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowWiFiHotSpotReporting",
        "Name": "Value",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowAutoConnectToWiFiSenseHotspots",
        "Name": "Value",
        "Type": "DWord",
        "Value": "0"
      }
    ]
  },
  "EnableEndTaskRightClick": {
    "Content": "Enable End Task With Right Click",
    "Description": "Enables option to end task when right clicking a program in the taskbar.",
    "category": "Enhancement",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\TaskbarDeveloperSettings",
        "Name": "TaskbarEndTask",
        "Type": "DWord",
        "Value": "1"
      }
    ]
  },
  "SetServicesManual": {
    "Content": "Set Services to Manual",
    "Description": "Sets various Windows services to manual startup to improve boot time.",
    "category": "Performance",
    "service": [
      {
        "Name": "AJRouter",
        "StartupType": "Manual"
      },
      {
        "Name": "ALG",
        "StartupType": "Manual"
      },
      {
        "Name": "AppMgmt",
        "StartupType": "Manual"
      },
      {
        "Name": "tzautoupdate",
        "StartupType": "Manual"
      },
      {
        "Name": "BDESVC",
        "StartupType": "Manual"
      },
      {
        "Name": "wbengine",
        "StartupType": "Manual"
      },
      {
        "Name": "DPS",
        "StartupType": "Manual"
      }
    ]
  },
  "EnableDarkMode": {
    "Content": "Enable Dark Mode",
    "Description": "Enables dark mode for Windows and applications.",
    "category": "Enhancement",
    "registry": [
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        "Name": "AppsUseLightTheme",
        "Type": "DWord",
        "Value": "0"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        "Name": "SystemUsesLightTheme",
        "Type": "DWord",
        "Value": "0"
      }
    ]
  },
  "SetClassicRightClickMenu": {
    "Content": "Set Classic Right-Click Menu",
    "Description": "Restores the classic context menu in Windows 11. (Note: Requires Explorer restart)",
    "category": "Enhancement",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\\InprocServer32",
        "Name": "(Default)",
        "Type": "String",
        "Value": ""
      }
    ],
    "InvokeScript": [
      "Write-Host 'Registry changes applied. Explorer restart required for classic menu to take effect.' -ForegroundColor Yellow",
      "Write-Host 'Explorer will restart automatically in 3 seconds...' -ForegroundColor Yellow",
      "Start-Sleep -Seconds 3",
      "taskkill /f /im explorer.exe",
      "Start-Sleep -Seconds 2", 
      "Start-Process explorer.exe"
    ]
  }
}
'@ | ConvertFrom-Json

# Helper Functions
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Type,
        [string]$Value
    )
    
    try {
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Convert value based on type
        $actualValue = switch ($Type) {
            "DWord" { [int]$Value }
            "String" { [string]$Value }
            "Binary" { [byte[]]$Value }
            default { $Value }
        }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $actualValue -Type $Type
    }
    catch {
        throw "Failed to set registry value: $Path\$Name - $($_.Exception.Message)"
    }
}

function Set-ServiceStartup {
    param(
        [string]$ServiceName,
        [string]$StartupType
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Set-Service -Name $ServiceName -StartupType $StartupType
            return $null  # Success, no warning
        }
        else {
            # Service doesn't exist - this is common and not an error for many services
            return "Service not found: $ServiceName (this is normal for some Windows versions)"
        }
    }
    catch {
        throw "Failed to configure service: $ServiceName - $($_.Exception.Message)"
    }
}

function Set-ScheduledTaskState {
    param(
        [string]$TaskName,
        [string]$State
    )
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName.Split('\')[-1] -ErrorAction SilentlyContinue
        if ($task) {
            if ($State -eq "Disabled") {
                Disable-ScheduledTask -TaskName $TaskName | Out-Null
            }
            else {
                Enable-ScheduledTask -TaskName $TaskName | Out-Null
            }
            return $null  # Success, no warning
        }
        else {
            # Task doesn't exist - this is common and not an error
            return "Scheduled task not found: $TaskName (this is normal for some Windows versions)"
        }
    }
    catch {
        throw "Failed to configure scheduled task: $TaskName - $($_.Exception.Message)"
    }
}

function Invoke-ScriptBlock {
    param(
        [string]$Script
    )
    
    try {
        $scriptBlock = [scriptblock]::Create($Script)
        Invoke-Command -ScriptBlock $scriptBlock
    }
    catch {
        throw "Script execution failed - $($_.Exception.Message)"
    }
}

function Apply-Tweak {
    param(
        [string]$TweakName
    )
    
    $tweak = $tweaksConfig.$TweakName
    if (!$tweak) {
        throw "Tweak not found: $TweakName"
    }
    
    $errors = @()
    $warnings = @()
    
    # Apply registry changes
    if ($tweak.registry) {
        foreach ($reg in $tweak.registry) {
            try {
                Set-RegistryValue -Path $reg.Path -Name $reg.Name -Type $reg.Type -Value $reg.Value
            }
            catch {
                $errors += $_.Exception.Message
            }
        }
    }
    
    # Apply service changes
    if ($tweak.service) {
        foreach ($svc in $tweak.service) {
            try {
                $warning = Set-ServiceStartup -ServiceName $svc.Name -StartupType $svc.StartupType
                if ($warning) {
                    $warnings += $warning
                }
            }
            catch {
                $errors += $_.Exception.Message
            }
        }
    }
    
    # Apply scheduled task changes
    if ($tweak.ScheduledTask) {
        foreach ($task in $tweak.ScheduledTask) {
            try {
                $warning = Set-ScheduledTaskState -TaskName $task.Name -State $task.State
                if ($warning) {
                    $warnings += $warning
                }
            }
            catch {
                $errors += $_.Exception.Message
            }
        }
    }
    
    # Execute scripts
    if ($tweak.InvokeScript) {
        foreach ($script in $tweak.InvokeScript) {
            try {
                Invoke-ScriptBlock -Script $script
            }
            catch {
                $errors += $_.Exception.Message
            }
        }
    }
    
    # Return results
    return @{
        Errors = $errors
        Warnings = $warnings
    }
}

# Main Script Logic
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    exit 1
}

# Apply all tweaks automatically
Write-Host "WinUtil Tweaks - Auto Apply Mode" -ForegroundColor White
Write-Host "This script will automatically apply all Windows tweaks and optimizations." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel or wait 3 seconds to continue..." -ForegroundColor Yellow

# 3 second countdown
for ($i = 3; $i -gt 0; $i--) {
    Write-Host "Starting in $i seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

Write-Host "`nApplying tweaks..." -ForegroundColor Green

# Initialize counters
$successCount = 0
$failureCount = 0
$totalTweaks = $tweaksConfig.PSObject.Properties.Name.Count
$failedTweaks = @()

Write-Host "`nApplying $totalTweaks tweaks..." -ForegroundColor Cyan

# Apply all tweaks with progress bar
$tweakIndex = 0
foreach ($tweakName in $tweaksConfig.PSObject.Properties.Name) {
    $tweak = $tweaksConfig.$tweakName
    $tweakIndex++
    
    # Update progress bar
    $percentComplete = [math]::Round(($tweakIndex / $totalTweaks) * 100)
    Write-Progress -Activity "Applying Windows Tweaks" -Status "Processing: $($tweak.Content)" -PercentComplete $percentComplete
    
    try {
        $result = Apply-Tweak -TweakName $tweakName
        
        if ($result.Errors.Count -gt 0) {
            $failureCount++
            $failedTweaks += $tweak.Content
        } else {
            $successCount++
        }
    }
    catch {
        $failureCount++
        $failedTweaks += $tweak.Content
    }
}

# Complete progress bar
Write-Progress -Activity "Applying Windows Tweaks" -Completed

# Summary
Write-Host "`nCOMPLETED!" -ForegroundColor Green
Write-Host "Total: $totalTweaks | Success: $successCount | Failed: $failureCount" -ForegroundColor White

if ($failedTweaks.Count -gt 0) {
    Write-Host "`nFailed tweaks:" -ForegroundColor Red
    foreach ($tweak in $failedTweaks) {
        Write-Host "  - $tweak" -ForegroundColor Red
    }
    Write-Host "Note: Some failures are normal due to Windows version differences." -ForegroundColor Gray
}

Write-Host "`nWindows optimization completed!" -ForegroundColor Green
Write-Host "Restart recommended for all changes to take effect." -ForegroundColor Yellow

