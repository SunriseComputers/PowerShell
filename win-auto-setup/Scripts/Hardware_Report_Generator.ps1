
# Hardware Information Report Generator
Write-Host "=== SYSTEM HARDWARE INFORMATION REPORT ===" -ForegroundColor Green
Write-Host "Generated on: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

# Get Computer Name
Write-Host "COMPUTER INFORMATION" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
$ComputerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Host "Computer Name: $($ComputerInfo.Name)"
Write-Host "Domain: $($ComputerInfo.Domain)"
Write-Host "Manufacturer: $($ComputerInfo.Manufacturer)"
Write-Host "Model: $($ComputerInfo.Model)"

# Get System Type (UEFI/Legacy)
$SystemType = "Unknown"
try {
    $SecureBootState = Get-SecureBootUEFI -Name $env:COMPUTERNAME -ErrorAction SilentlyContinue
    if ($SecureBootState) {
        $SystemType = "UEFI"
    } else {
        # Check for UEFI registry key
        if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") {
            $SystemType = "UEFI"
        } else {
            $SystemType = "Legacy BIOS"
        }
    }
} catch {
    $SystemType = "Legacy BIOS"  # Default to Legacy BIOS if detection fails
}
Write-Host "System Type: $SystemType"
Write-Host ""

# Get RAM Information
Write-Host "RAM INFORMATION" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
$MemoryModules = Get-CimInstance -ClassName Win32_PhysicalMemory
$MemorySlots = Get-CimInstance -ClassName Win32_PhysicalMemoryArray

Write-Host "Total Memory Slots: $($MemorySlots.MemoryDevices)"
Write-Host "Memory Modules Installed: $($MemoryModules.Count)"

# Check XMP Profile Status
$XMPStatus = "Unknown"
try {
    $BaseSpeed = ($MemoryModules | Measure-Object -Property Speed -Minimum).Minimum
    $ConfiguredSpeed = ($MemoryModules | Measure-Object -Property ConfiguredClockSpeed -Maximum).Maximum
    
    if ($ConfiguredSpeed -gt $BaseSpeed) {
        $XMPStatus = "Enabled (Memory running at $ConfiguredSpeed MHz)"
    } else {
        $XMPStatus = "Disabled (Memory running at standard JEDEC speed)"
    }
} catch {
    $XMPStatus = "Unable to determine"
}

Write-Host "XMP Profile Status: $XMPStatus" -ForegroundColor $(if($XMPStatus -like "*Enabled*") { "Green" } elseif($XMPStatus -like "*Disabled*") { "Yellow" } else { "Red" })
Write-Host ""

foreach ($Memory in $MemoryModules) {
    $CapacityGB = [math]::Round($Memory.Capacity / 1GB, 2)
    $FormFactor = switch ($Memory.FormFactor) {
        8 { "DIMM" }
        12 { "SO-DIMM" }
        default { "Unknown" }
    }

    Write-Host "RAM Slot: $($Memory.DeviceLocator)" -ForegroundColor Yellow
    Write-Host "  Manufacturer: $($Memory.Manufacturer)"
    Write-Host "  Capacity: $CapacityGB GB"
    Write-Host "  Speed: $($Memory.Speed) MHz"
    Write-Host "  Configured Speed: $($Memory.ConfiguredClockSpeed) MHz"
    Write-Host "  Form Factor: $FormFactor"
    Write-Host "  Part Number: $($Memory.PartNumber)"
    Write-Host "  Serial Number: $($Memory.SerialNumber)"
    Write-Host ""
}

# Get Storage Information (HDD and SSD)
Write-Host "STORAGE INFORMATION" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

# Get Physical Disks
$PhysicalDisks = Get-PhysicalDisk
$LogicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk

# Determine OS Installation Drive
$SystemDrive = $env:SystemDrive
Write-Host "Operating System installed on: $SystemDrive" -ForegroundColor Green
Write-Host ""

foreach ($Disk in $PhysicalDisks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB, 2)
    $MediaType = switch ($Disk.MediaType) {
        3 { "HDD (Hard Disk Drive)" }
        4 { "SSD (Solid State Drive)" }
        5 { "SCM (Storage Class Memory)" }
        default { "Unknown" }
    }

    Write-Host "Disk $($Disk.DeviceId): $($Disk.FriendlyName)" -ForegroundColor Yellow
    Write-Host "  Manufacturer: $($Disk.Manufacturer)"
    Write-Host "  Model: $($Disk.Model)"
    Write-Host "  Type: $MediaType"
    Write-Host "  Size: $SizeGB GB"
    Write-Host "  Health Status: $($Disk.HealthStatus)"
    Write-Host "  Operational Status: $($Disk.OperationalStatus)"

    # Get partitions for this disk
    $Partitions = Get-Partition -DiskNumber $Disk.DeviceId -ErrorAction SilentlyContinue
    if ($Partitions) {
        Write-Host "  Partitions:"
        foreach ($Partition in $Partitions) {
            if ($Partition.DriveLetter) {
                $LogicalDisk = $LogicalDisks | Where-Object { $_.DeviceID -eq "$($Partition.DriveLetter):" }
                $UsedSpaceGB = [math]::Round(($LogicalDisk.Size - $LogicalDisk.FreeSpace) / 1GB, 2)
                $FreeSpaceGB = [math]::Round($LogicalDisk.FreeSpace / 1GB, 2)

                Write-Host "    Drive $($Partition.DriveLetter): ($($LogicalDisk.VolumeName))"
                Write-Host "      Size: $([math]::Round($Partition.Size / 1GB, 2)) GB"
                Write-Host "      Used: $UsedSpaceGB GB"
                Write-Host "      Free: $FreeSpaceGB GB"
                Write-Host "      File System: $($LogicalDisk.FileSystem)"

                if ($Partition.DriveLetter -eq $SystemDrive.Replace(":", "")) {
                    Write-Host "      *** OS INSTALLATION DRIVE ***" -ForegroundColor Green
                }
            }
        }
    }
    Write-Host ""
}

# Get Graphics Card Information
Write-Host "GRAPHICS CARD INFORMATION" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
$VideoControllers = Get-CimInstance -ClassName Win32_VideoController

# Run dxdiag and parse Display Memory
$dxdiagPath = "$env:TEMP\dxdiag.txt"
Start-Process dxdiag -ArgumentList "/t $dxdiagPath" -Wait
$dxdiagContent = Get-Content $dxdiagPath
$gpuMemLines = $dxdiagContent | Select-String -Pattern "Display Memory"
$gpuMemDict = @{}
foreach ($line in $gpuMemLines) {
    if ($line -match "^\s*Display Memory:\s*(\d+) MB") {
        $memMB = [int]$matches[1]
        $gpuIndex = $gpuMemDict.Count
        $gpuMemDict[$gpuIndex] = $memMB
    }
}

$gpuIdx = 0
foreach ($GPU in $VideoControllers) {
    if ($GPU.Name -notlike "*Remote*" -and $GPU.Name -notlike "*Mirror*") {
        Write-Host "GPU: $($GPU.Name)" -ForegroundColor Yellow
        Write-Host "  Adapter Type: $($GPU.AdapterCompatibility)"
        Write-Host "  Driver Version: $($GPU.DriverVersion)"
        Write-Host "  Driver Date: $($GPU.DriverDate)"
        $dedicatedVRAM = "Unknown"
        $sharedMemory = "Unknown"
        # Use nvidia-smi for NVIDIA GPUs
        if ($GPU.Name -match "NVIDIA|GeForce|Quadro") {
            try {
                $nvVramRaw = & nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>$null
                if ($nvVramRaw) {
                    $nvVramGB = [math]::Round(($nvVramRaw -replace "[^0-9]", "") / 1024, 2)
                    $dedicatedVRAM = "$nvVramGB GB (nvidia-smi)"
                }
            } catch {
                # Fallback to AdapterRAM if nvidia-smi fails
                if ($GPU.AdapterRAM -gt 0) {
                    $dedicatedVRAM = "{0} GB (WMI)" -f ([math]::Round($GPU.AdapterRAM / 1GB, 2))
                }
            }
        } elseif ($GPU.AdapterRAM -gt 0) {
            $dedicatedVRAM = "{0} GB (WMI)" -f ([math]::Round($GPU.AdapterRAM / 1GB, 2))
        }
        # Shared Memory from dxdiag
        if ($gpuMemDict.ContainsKey($gpuIdx)) {
            $sharedVal = [math]::Round($gpuMemDict[$gpuIdx] / 1024, 2)
            $sharedMemory = "{0} GB" -f $sharedVal
            if ($sharedVal -gt 24) {
                $sharedMemory += " [Warning: Value unusually high, may include shared memory]"
            }
        }
        Write-Host "  Dedicated VRAM: $dedicatedVRAM"
        Write-Host "  Shared Memory: $sharedMemory"
        Write-Host "  Current Resolution: $($GPU.CurrentHorizontalResolution) x $($GPU.CurrentVerticalResolution)"
        Write-Host "  Current Refresh Rate: $($GPU.CurrentRefreshRate) Hz"
        Write-Host "  Status: $($GPU.Status)"
        Write-Host ""
        $gpuIdx++
    }
}

# Get Processor Information
Write-Host "PROCESSOR INFORMATION" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
$Processors = Get-CimInstance -ClassName Win32_Processor

foreach ($CPU in $Processors) {
    Write-Host "Processor: $($CPU.Name)" -ForegroundColor Yellow
    Write-Host "  Manufacturer: $($CPU.Manufacturer)"
    Write-Host "  Architecture: $($CPU.Architecture)"
    Write-Host "  Family: $($CPU.Family)"
    Write-Host "  Model: $($CPU.Model)"
    Write-Host "  Stepping: $($CPU.Stepping)"
    Write-Host "  Physical Cores: $($CPU.NumberOfCores)"
    Write-Host "  Logical Processors (Threads): $($CPU.NumberOfLogicalProcessors)"
    Write-Host "  Current Clock Speed: $($CPU.CurrentClockSpeed) MHz"
    Write-Host "  Max Clock Speed: $($CPU.MaxClockSpeed) MHz"
    Write-Host "  Socket Designation: $($CPU.SocketDesignation)"
    Write-Host "  L2 Cache Size: $([math]::Round($CPU.L2CacheSize / 1KB, 0)) KB" -ErrorAction SilentlyContinue
    Write-Host "  L3 Cache Size: $([math]::Round($CPU.L3CacheSize / 1KB, 0)) KB" -ErrorAction SilentlyContinue
    Write-Host ""
}

# Generate Summary Report
Write-Host "SYSTEM SUMMARY" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
$TotalRAM = ($MemoryModules | Measure-Object -Property Capacity -Sum).Sum / 1GB
$TotalStorage = ($PhysicalDisks | Measure-Object -Property Size -Sum).Sum / 1GB

Write-Host "Computer: $($ComputerInfo.Name)"
Write-Host "Total RAM: $([math]::Round($TotalRAM, 2)) GB ($($MemoryModules.Count) modules)"
Write-Host "Total Storage: $([math]::Round($TotalStorage, 2)) GB"
Write-Host "CPU: $($Processors[0].Name) ($($Processors[0].NumberOfCores) cores, $($Processors[0].NumberOfLogicalProcessors) threads)"
Write-Host "GPU(s): $($VideoControllers.Count) graphics adapter(s)"
Write-Host ""

# Automatically export report to desktop
$FileName = "Hardware_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$FilePath = Join-Path $DesktopPath $FileName

Write-Host "Exporting hardware report to desktop..." -ForegroundColor Yellow

# Create a simple text report without duplicating all the code
$ReportContent = @"
=== SYSTEM HARDWARE INFORMATION REPORT ===
Generated on: $(Get-Date)

COMPUTER INFORMATION
===================
Computer Name: $($ComputerInfo.Name)
Domain: $($ComputerInfo.Domain)
Manufacturer: $($ComputerInfo.Manufacturer)
Model: $($ComputerInfo.Model)
System Type: $SystemType

RAM INFORMATION
===============
Total Memory Slots: $($MemorySlots.MemoryDevices)
Memory Modules Installed: $($MemoryModules.Count)
XMP Profile Status: $XMPStatus

"@

# Add RAM module details
foreach ($Memory in $MemoryModules) {
    $CapacityGB = [math]::Round($Memory.Capacity / 1GB, 2)
    $FormFactor = switch ($Memory.FormFactor) { 8 { "DIMM" } 12 { "SO-DIMM" } default { "Unknown" } }
    $ReportContent += "RAM Slot: $($Memory.DeviceLocator)`n"
    $ReportContent += "  Manufacturer: $($Memory.Manufacturer)`n"
    $ReportContent += "  Capacity: $CapacityGB GB`n"
    $ReportContent += "  Speed: $($Memory.Speed) MHz`n"
    $ReportContent += "  Configured Speed: $($Memory.ConfiguredClockSpeed) MHz`n"
    $ReportContent += "  Form Factor: $FormFactor`n"
    $ReportContent += "  Part Number: $($Memory.PartNumber)`n"
    $ReportContent += "  Serial Number: $($Memory.SerialNumber)`n`n"
}

$ReportContent += @"
STORAGE INFORMATION
==================
Operating System installed on: $SystemDrive

"@

# Add storage details
foreach ($Disk in $PhysicalDisks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB, 2)
    $MediaType = switch ($Disk.MediaType) { 3 { "HDD (Hard Disk Drive)" } 4 { "SSD (Solid State Drive)" } 5 { "SCM (Storage Class Memory)" } default { "Unknown" } }
    $ReportContent += "Disk $($Disk.DeviceId): $($Disk.FriendlyName)`n"
    $ReportContent += "  Manufacturer: $($Disk.Manufacturer)`n"
    $ReportContent += "  Model: $($Disk.Model)`n"
    $ReportContent += "  Type: $MediaType`n"
    $ReportContent += "  Size: $SizeGB GB`n"
    $ReportContent += "  Health Status: $($Disk.HealthStatus)`n"
    $ReportContent += "  Operational Status: $($Disk.OperationalStatus)`n"
    
    $Partitions = Get-Partition -DiskNumber $Disk.DeviceId -ErrorAction SilentlyContinue
    if ($Partitions) {
        $ReportContent += "  Partitions:`n"
        foreach ($Partition in $Partitions) {
            if ($Partition.DriveLetter) {
                $LogicalDisk = $LogicalDisks | Where-Object { $_.DeviceID -eq "$($Partition.DriveLetter):" }
                $UsedSpaceGB = [math]::Round(($LogicalDisk.Size - $LogicalDisk.FreeSpace) / 1GB, 2)
                $FreeSpaceGB = [math]::Round($LogicalDisk.FreeSpace / 1GB, 2)
                $ReportContent += "    Drive $($Partition.DriveLetter): ($($LogicalDisk.VolumeName))`n"
                $ReportContent += "      Size: $([math]::Round($Partition.Size / 1GB, 2)) GB`n"
                $ReportContent += "      Used: $UsedSpaceGB GB`n"
                $ReportContent += "      Free: $FreeSpaceGB GB`n"
                $ReportContent += "      File System: $($LogicalDisk.FileSystem)`n"
                if ($Partition.DriveLetter -eq $SystemDrive.Replace(":", "")) {
                    $ReportContent += "      *** OS INSTALLATION DRIVE ***`n"
                }
            }
        }
    }
    $ReportContent += "`n"
}

$ReportContent += @"
GRAPHICS CARD INFORMATION
========================
"@

# Add GPU details
    $gpuIdx = 0
    foreach ($GPU in $VideoControllers) {
        if ($GPU.Name -notlike "*Remote*" -and $GPU.Name -notlike "*Mirror*") {
            $ReportContent += "`nGPU: $($GPU.Name)`n"
            $ReportContent += "  Adapter Type: $($GPU.AdapterCompatibility)`n"
            $ReportContent += "  Driver Version: $($GPU.DriverVersion)`n"
            $ReportContent += "  Driver Date: $($GPU.DriverDate)`n"
            $dedicatedVRAM = "Unknown"
            $sharedMemory = "Unknown"
            if ($GPU.Name -match "NVIDIA|GeForce|Quadro") {
                try {
                    $nvVramRaw = & nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>$null
                    if ($nvVramRaw) {
                        $nvVramGB = [math]::Round(($nvVramRaw -replace "[^0-9]", "") / 1024, 2)
                        $dedicatedVRAM = "$nvVramGB GB (nvidia-smi)"
                    }
                } catch {
                    if ($GPU.AdapterRAM -gt 0) {
                        $dedicatedVRAM = "{0} GB (WMI)" -f ([math]::Round($GPU.AdapterRAM / 1GB, 2))
                    }
                }
            } elseif ($GPU.AdapterRAM -gt 0) {
                $dedicatedVRAM = "{0} GB (WMI)" -f ([math]::Round($GPU.AdapterRAM / 1GB, 2))
            }
            if ($gpuMemDict.ContainsKey($gpuIdx)) {
                $sharedVal = [math]::Round($gpuMemDict[$gpuIdx] / 1024, 2)
                $sharedMemory = "{0} GB" -f $sharedVal
                if ($sharedVal -gt 24) {
                    $sharedMemory += " [Warning: Value unusually high, may include shared memory]"
                }
            }
            $ReportContent += "  Dedicated VRAM: $dedicatedVRAM`n"
            $ReportContent += "  Shared Memory: $sharedMemory`n"
            $ReportContent += "  Current Resolution: $($GPU.CurrentHorizontalResolution) x $($GPU.CurrentVerticalResolution)`n"
            $ReportContent += "  Current Refresh Rate: $($GPU.CurrentRefreshRate) Hz`n"
            $ReportContent += "  Status: $($GPU.Status)`n"
            $gpuIdx++
        }
    }

$ReportContent += @"

PROCESSOR INFORMATION
====================
"@

# Add CPU details
foreach ($CPU in $Processors) {
    $ReportContent += "`nProcessor: $($CPU.Name)`n"
    $ReportContent += "  Manufacturer: $($CPU.Manufacturer)`n"
    $ReportContent += "  Architecture: $($CPU.Architecture)`n"
    $ReportContent += "  Family: $($CPU.Family)`n"
    $ReportContent += "  Model: $($CPU.Model)`n"
    $ReportContent += "  Stepping: $($CPU.Stepping)`n"
    $ReportContent += "  Physical Cores: $($CPU.NumberOfCores)`n"
    $ReportContent += "  Logical Processors (Threads): $($CPU.NumberOfLogicalProcessors)`n"
    $ReportContent += "  Current Clock Speed: $($CPU.CurrentClockSpeed) MHz`n"
    $ReportContent += "  Max Clock Speed: $($CPU.MaxClockSpeed) MHz`n"
    $ReportContent += "  Socket Designation: $($CPU.SocketDesignation)`n"
    if ($CPU.L2CacheSize) { $ReportContent += "  L2 Cache Size: $([math]::Round($CPU.L2CacheSize / 1KB, 0)) KB`n" }
    if ($CPU.L3CacheSize) { $ReportContent += "  L3 Cache Size: $([math]::Round($CPU.L3CacheSize / 1KB, 0)) KB`n" }
}

$ReportContent += @"

SYSTEM SUMMARY
==============
Computer: $($ComputerInfo.Name)
System Type: $SystemType
Total RAM: $([math]::Round($TotalRAM, 2)) GB ($($MemoryModules.Count) modules)
XMP Profile Status: $XMPStatus
Total Storage: $([math]::Round($TotalStorage, 2)) GB
CPU: $($Processors[0].Name) ($($Processors[0].NumberOfCores) cores, $($Processors[0].NumberOfLogicalProcessors) threads)
GPU(s): $($VideoControllers.Count) graphics adapter(s)
"@

# Write to file
try {
    $ReportContent | Out-File -FilePath $FilePath -Encoding UTF8
    Write-Host "Hardware report automatically exported to desktop!" -ForegroundColor Green
    Write-Host "File saved as: $FileName" -ForegroundColor Cyan
} catch {
    Write-Host "Error saving report: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Hardware inventory complete!" -ForegroundColor Green
