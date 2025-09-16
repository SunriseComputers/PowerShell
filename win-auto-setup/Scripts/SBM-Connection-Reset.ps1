# Network Adapter and SMB Connection Management Script
# Requires Administrator privileges for service operations

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Main script execution
Write-Host "=== Network Adapter and SMB Connection Management ===" -ForegroundColor Green
Write-Host ""

# Check for Administrator privileges
if (-not (Test-Administrator)) {
    Write-Warning "This script requires Administrator privileges for service operations."
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

try {
    # 1. Get Link Speed of Built-in Network Cards
    Write-Host "1. Getting Network Adapter Information..." -ForegroundColor Cyan
    
    $networkAdapters = Get-NetAdapter | Select-Object InterfaceDescription, Name, Status, LinkSpeed
    $networkAdapters | Format-Table -AutoSize
     
    # 2. Show all ongoing connections through SMB Protocol
    Write-Host "2. Getting SMB Connections..." -ForegroundColor Cyan

    $smbConnections = Get-SmbConnection -ErrorAction SilentlyContinue
    if ($smbConnections) {
        $smbConnections | Format-Table -AutoSize
        Write-Host "Found $($smbConnections.Count) SMB connection(s)`n" -ForegroundColor Green
    } else {
        Write-Host "No active SMB connections found.`n" -ForegroundColor Yellow
    }
       
    # 3. Reset all ongoing connections through SMB protocol
    Write-Host "3. Resetting SMB connections by restarting LanmanWorkstation service...`n" -ForegroundColor Cyan
    
    # Confirm before proceeding
    $confirm = Read-Host "This will disconnect all network connections. Continue? (Y/N)"
    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
        
        # Stop the LanmanWorkstation service
        Write-Host "Stopping LanmanWorkstation service..." -ForegroundColor Yellow
        Stop-Service -Name "LanmanWorkstation" -Force -ErrorAction Stop
        Write-Host "Service stopped successfully." -ForegroundColor Green
        
        # Wait for 10 seconds
        Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # Start the service again
        Write-Host "Starting LanmanWorkstation service..." -ForegroundColor Yellow
        Start-Service -Name "LanmanWorkstation" -ErrorAction Stop
        Write-Host "Service started successfully." -ForegroundColor Green
        
        # Verify service status
        $serviceStatus = Get-Service -Name "LanmanWorkstation"
        Write-Host "Current service status: $($serviceStatus.Status)" -ForegroundColor Green
        
    } else {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Write-Host "Please ensure you are running as Administrator and try again." -ForegroundColor Red
}

Write-Host ""
Write-Host "Script completed." -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
