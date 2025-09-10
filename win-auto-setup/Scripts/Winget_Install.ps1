#Requires -RunAsAdministrator

param([switch]$Quiet)

$ErrorActionPreference = "Stop"
$ProgressPreference = if ($Quiet) { "SilentlyContinue" } else { "Continue" }

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    if (-not $Quiet) { Write-Host $Message -ForegroundColor $Color }
}

function Test-WinGetWorking {
    try {
        $version = winget --version 2>$null
        if (-not $version) { return $false }
        $null = winget source list --accept-source-agreements 2>$null
        return $true
    } catch {
        return $false
    }
}

function Update-PathEnvironment {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Test-Prerequisites {
    $buildNumber = [int](Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
    $psVersion = $PSVersionTable.PSVersion.Major
    
    Write-Log "Windows Build: $buildNumber, PowerShell: $psVersion" "Gray"
    
    if ($buildNumber -lt 17763) { Write-Log "WARNING: Windows 10 v1809+ recommended" "Yellow" }
    if ($psVersion -lt 5) { Write-Log "ERROR: PowerShell 5.0+ required" "Red"; return $false }
    
    return $true
}

function Install-ChocolateyQuick {
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) { 
            Write-Log "Chocolatey already installed" "Green"
            return $true 
        }
        
        Write-Log "Installing Chocolatey..." "Yellow"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $originalPolicy = Get-ExecutionPolicy
        Set-ExecutionPolicy Bypass -Scope Process -Force
        
        $installScript = Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing
        Invoke-Expression $installScript.Content
        
        Set-ExecutionPolicy $originalPolicy -Scope Process -Force
        Update-PathEnvironment
        Start-Sleep -Seconds 5
        
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Log "Chocolatey installed successfully" "Green"
            return $true
        } else {
            Write-Log "Chocolatey installation failed" "Red"
            return $false
        }
    } catch {
        Write-Log "Chocolatey error: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-WinGetViaChoco {
    try {
        Write-Log "Installing WinGet via Chocolatey..." "Yellow"
        $null = Start-Process "choco" -ArgumentList "upgrade", "chocolatey", "-y" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
        
        $result = Start-Process "choco" -ArgumentList "install", "winget", "-y", "--force" -Wait -NoNewWindow -PassThru
        
        if ($result.ExitCode -eq 0) {
            Write-Log "WinGet installed via Chocolatey" "Green"
            Update-PathEnvironment
            Start-Sleep -Seconds 10
            return Test-WinGetWorking
        } else {
            Write-Log "Chocolatey WinGet install failed (exit code: $($result.ExitCode))" "Red"
            return $false
        }
    } catch {
        Write-Log "WinGet via Chocolatey error: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-WinGetModern {
    try {
        $buildNumber = [int](Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
        if ($buildNumber -lt 17763) { 
            Write-Log "Windows build too old for modern installation" "Yellow"
            return $false 
        }
        
        Write-Log "Installing via PowerShell module..." "Yellow"
        
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction SilentlyContinue
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        
        Install-Module "Microsoft.WinGet.Client" -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
        Import-Module Microsoft.WinGet.Client -Force -ErrorAction Stop
        
        Repair-WinGetPackageManager -Force -Latest -ErrorAction Stop
        Start-Sleep -Seconds 8
        
        return Test-WinGetWorking
    } catch {
        Write-Log "Modern installation error: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-WinGetDirect {
    try {
        Write-Log "Attempting direct installation..." "Yellow"
        
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1
        
        if (-not $asset) {
            Write-Log "Could not find WinGet msixbundle" "Red"
            return $false
        }
        
        $tempPath = "$env:TEMP\winget.msixbundle"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempPath -UseBasicParsing
        Add-AppxPackage -Path $tempPath -ForceApplicationShutdown -ErrorAction Stop
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        
        Start-Sleep -Seconds 5
        return Test-WinGetWorking
    } catch {
        Write-Log "Direct installation error: $($_.Exception.Message)" "Red"
        return $false
    }
}

# MAIN EXECUTION
function Main {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Log "ERROR: Administrator privileges required" "Red"
        exit 1
    }
    
    Write-Log "Installing Latest WinGet" "Cyan"
    Write-Log "========================" "Cyan"
    
    if (-not (Test-Prerequisites)) {
        Write-Log "ERROR: Prerequisites not met" "Red"
        exit 1
    }
    
    if (Test-WinGetWorking) {
        $currentVersion = winget --version 2>$null
        Write-Log "Current: $currentVersion -> Installing Latest" "Yellow"
    } else {
        Write-Log "WinGet not found -> Installing Latest" "Yellow"
    }
    
    # Try installation methods in order
    $methods = @(
        { Write-Log "Method 1: PowerShell module" "Cyan"; Install-WinGetModern },
        { Write-Log "Method 2: Direct GitHub download" "Cyan"; Install-WinGetDirect },
        { Write-Log "Method 3: Chocolatey" "Cyan"; Install-ChocolateyQuick -and Install-WinGetViaChoco }
    )
    
    $installSuccess = $false
    foreach ($method in $methods) {
        if (& $method) {
            $installSuccess = $true
            break
        }
    }
    
    if (-not $installSuccess) {
        Write-Log "ERROR: All installation methods failed" "Red"
        Write-Log "Try Windows Update or Microsoft Store installation" "Yellow"
        exit 1
    }
    
    if (Test-WinGetWorking) {
        $newVersion = winget --version 2>$null
        Write-Log "SUCCESS! Version: $newVersion" "Green"
    } else {
        Write-Log "ERROR: Installation completed but WinGet test failed" "Red"
        Write-Log "A restart may be required" "Yellow"
        exit 1
    }
}

Main
