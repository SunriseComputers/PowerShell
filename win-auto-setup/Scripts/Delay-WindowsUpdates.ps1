# Check for Administrator rights
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "❌ This script must be run as Administrator." -ForegroundColor Red
    exit
}

$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$AUPath = "$RegPath\AU"

# Create registry keys if they don't exist
If (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
If (-not (Test-Path $AUPath)) {
    New-Item -Path $AUPath -Force | Out-Null
}

# Set registry values
$Settings = @{
    "DeferFeatureUpdates"                = 1      # Enable delay
    "DeferFeatureUpdatesPeriodInDays"   = 730    # 2 years
    "DeferQualityUpdates"               = 1
    "DeferQualityUpdatesPeriodInDays"   = 4
}
$AUSettings = @{
    "AUOptions" = 2  # Notify before download/install
}

foreach ($name in $Settings.Keys) {
    New-ItemProperty -Path $RegPath -Name $name -PropertyType DWord -Value $Settings[$name] -Force | Out-Null
}
foreach ($name in $AUSettings.Keys) {
    New-ItemProperty -Path $AUPath -Name $name -PropertyType DWord -Value $AUSettings[$name] -Force | Out-Null
}

Write-Host "✅ Windows Update delay settings applied successfully for ALL Windows editions!" -ForegroundColor Green

