# Set the location to the registry
Set-Location -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows'

# Create a new Key
Get-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' | New-Item -Name 'LanmanWorkstation' -Force

# Create new items with values
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation' -Name 'AllowInsecureGuestAuth' -Value "1" -PropertyType DWORD -Force

# Get out of the Registry
Pop-Location

#To disable SMB signing requirement
Set-SmbClientConfiguration -RequireSecuritySignature $false

#To disable guest fallback
Set-SmbClientConfiguration -EnableInsecureGuestLogons $true
