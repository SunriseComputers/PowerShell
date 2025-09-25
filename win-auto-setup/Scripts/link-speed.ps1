Write-Host "Getting Network Adapter Information..." -ForegroundColor Cyan
    
    $networkAdapters = Get-NetAdapter | Select-Object InterfaceDescription, Name, Status, LinkSpeed
    $networkAdapters | Format-Table -AutoSize