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

function Install-ChocolateyQuick {
    try {
        if (Get-Command choco -ErrorAction Ignore) { return $true }
        
        Write-Log "Installing Chocolatey..." "Yellow"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Start-Sleep -Seconds 5
        
        return (Get-Command choco -ErrorAction Ignore) -ne $null
    } catch {
        return $false
    }
}

function Install-WinGetViaChoco {
    try {
        Write-Log "Installing WinGet via Chocolatey..." "Yellow"
        $result = Start-Process -FilePath "choco" -ArgumentList "install", "winget", "-y", "--force" -Wait -NoNewWindow -PassThru
        
        if ($result.ExitCode -eq 0) {
            $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            Start-Sleep -Seconds 10
            return Test-WinGetWorking
        }
        return $false
    } catch {
        return $false
    }
}

function Install-WinGetModern {
    try {
        $buildNumber = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
        if ([int]$buildNumber -lt 19041) { return $false }
        
        Write-Log "Installing via PowerShell module..." "Yellow"
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction SilentlyContinue
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        Install-Module "Microsoft.WinGet.Client" -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
        Import-Module Microsoft.WinGet.Client -Force
        Repair-WinGetPackageManager -Force -Latest
        Start-Sleep -Seconds 8
        
        return Test-WinGetWorking
    } catch {
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
    
    # Show current version if exists
    if (Test-WinGetWorking) {
        $currentVersion = winget --version 2>$null
        Write-Log "Current: $currentVersion -> Installing Latest" "Yellow"
    } else {
        Write-Log "WinGet not found -> Installing Latest" "Yellow"
    }
    
    # Try modern method first, then Chocolatey
    if (-not (Install-WinGetModern)) {
        if (-not (Install-ChocolateyQuick) -or -not (Install-WinGetViaChoco)) {
            Write-Log "ERROR: Installation failed" "Red"
            exit 1
        }
    }
    
    # Verify success
    if (Test-WinGetWorking) {
        $newVersion = winget --version 2>$null
        Write-Log "SUCCESS! Version: $newVersion" "Green"
    } else {
        Write-Log "ERROR: Installation failed - restart may be needed" "Red"
        exit 1
    }
}

Main
