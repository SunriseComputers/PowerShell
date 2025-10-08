# ===============================================================================
# PowerShell Windows Auto-Setup Tool - GitHub Version
# ===============================================================================
# 
# This script is designed to be run directly from GitHub using:
# irm https://raw.githubusercontent.com/SunriseComputers/PowerShell/refs/heads/main/win-auto-setup/main.ps1 | iex
#
# Repository structure:
# ├── win-auto-setup/
# │   ├── main.ps1 (this file)
# │   ├── Scripts/
# │   │   ├── Perfomance_Tweaks.ps1
# │   │   ├── Winget_Install.ps1
# │   │   ├── Online-app-Install.ps1
# │   │   ├── Delay-WindowsUpdates.ps1
# │   │   ├── App_Remover.ps1
# │   │   ├── Lanman_Network.ps1
# │   │   ├── SMB-Connection-Reset.ps1
# │   │   ├── link-speed.ps1
# │   │   └── Hardware_Report_Generator.ps1
# │   └── Files/
# │       └── S_Logo.png (optional - script works without it)
#
# Note: If S_Logo.png is missing, the script will continue without the logo
# ===============================================================================

# Command line parameter handling
param(
    [string]$AutoRun = ""
)

# Function to check if running as administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as administrator
if (-not (Test-IsAdmin)) {
    Write-Host "=" * 60 -ForegroundColor Red
    Write-Host "ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Red
    Write-Host "=" * 60 -ForegroundColor Red
    Write-Host ""
    Write-Host "This script requires Administrator privileges to:" -ForegroundColor Yellow
    Write-Host "- Set execution policy to Unrestricted" -ForegroundColor White
    Write-Host "- Install and manage applications" -ForegroundColor White
    Write-Host "- Modify system settings and registry" -ForegroundColor White
    Write-Host "- Remove bloatware applications" -ForegroundColor White
    Write-Host ""
    Write-Host "Starting elevated PowerShell session..." -ForegroundColor Cyan
    Write-Host "Please accept the UAC prompt to continue." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        # Get the current script path
        $scriptPath = $MyInvocation.MyCommand.Definition
        
        # Prepare arguments for the elevated process
        $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
        
        # Add AutoRun parameter if it was provided
        if ($AutoRun) {
            $arguments += " -AutoRun `"$AutoRun`""
        }
        
        # Start elevated PowerShell process
        Start-Process powershell -ArgumentList $arguments -Verb RunAs
        
        Write-Host "Elevated session started. This window will close." -ForegroundColor Green
        Write-Host "Please continue in the new Administrator window." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        exit 0
        
    } catch {
        Write-Host ""
        Write-Host "ERROR: Failed to start elevated session." -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please manually run PowerShell as Administrator:" -ForegroundColor Yellow
        Write-Host "1. Right-click on PowerShell" -ForegroundColor White
        Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
        Write-Host "3. Run this script again" -ForegroundColor White
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Set execution policy to Unrestricted
Write-Host "Setting execution policy to Unrestricted..." -ForegroundColor Cyan
try {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force
    Write-Host "Execution policy set to Unrestricted successfully." -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not set execution policy. Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "The script will continue, but some operations may fail." -ForegroundColor Yellow
}
Write-Host ""

# Load required assemblies for WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Set the GitHub repository base URL
$global:GitHubBaseUrl = "https://raw.githubusercontent.com/SunriseComputers/PowerShell/refs/heads/main/win-auto-setup"

# Function to get GitHub script URL
function Get-GitHubScriptUrl {
    param([string]$ScriptName)
    return "$global:GitHubBaseUrl/Scripts/$ScriptName"
}

# Function to get GitHub file URL
function Get-GitHubFileUrl {
    param([string]$FilePath)
    return "$global:GitHubBaseUrl/$FilePath"
}

# Function to download and execute script from GitHub
function Invoke-GitHubScript {
    param([string]$ScriptName, [array]$Arguments = @(), [switch]$ShowWindow = $false)
    
    $scriptUrl = Get-GitHubScriptUrl $ScriptName
    try {
        # Special handling for interactive scripts that need confirmation
        if ($ScriptName -eq "SMB-Connection-Reset.ps1") {
            $result = [System.Windows.MessageBox]::Show(
                "This will reset all SMB connections by restarting the LanmanWorkstation service.`n`nThis will disconnect all network connections. Do you want to continue?", 
                "Reset SMB Connections", 
                [System.Windows.MessageBoxButton]::YesNo, 
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($result -ne [System.Windows.MessageBoxResult]::Yes) {
                Write-Host "SMB Connection Reset cancelled by user." -ForegroundColor Yellow
                return
            }
        }

        # Download the script content
        $scriptContent = Invoke-RestMethod -Uri $scriptUrl -UseBasicParsing

        # Remove common interactive elements
        $scriptContent = $scriptContent -replace 'Read-Host.*Press.*key.*', '# Removed pause'
        $scriptContent = $scriptContent -replace '\$null\s*=\s*\$Host\.UI\.RawUI\.ReadKey.*', '# Removed pause'
        $scriptContent = $scriptContent -replace 'pause\s*$', '# Removed pause'
        $scriptContent = $scriptContent -replace 'Read-Host\s*$', '# Removed pause'
        
        # Create script block
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        
        # Execute based on arguments and window preferences
        if ($Arguments.Count -gt 0) {
            return & $scriptBlock @Arguments
        } elseif ($ShowWindow) {
            Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -Command `"$scriptContent`"" -Wait
        } else {
            return & $scriptBlock
        }
    } catch {
        Write-Host "Error executing script from GitHub: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}


# Function to get content from GitHub file
function Get-GitHubFileContent {
    param([string]$FilePath)
    
    $fileUrl = Get-GitHubFileUrl $FilePath
    try {
        return Invoke-RestMethod -Uri $fileUrl -UseBasicParsing
    } catch {
        Write-Host "Error downloading file from GitHub: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# UI Helper Functions
function Get-ButtonTemplate {
    return @"
<ControlTemplate TargetType="Button" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Border Background="{TemplateBinding Background}" 
            BorderBrush="{TemplateBinding BorderBrush}" 
            BorderThickness="{TemplateBinding BorderThickness}" 
            CornerRadius="4">
        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Border>
</ControlTemplate>
"@
}

function New-StyledButton {
    param(
        [string]$Content,
        [string]$Background = '#FF6F00',
        [string]$Foreground = 'White',
        [int]$FontSize = 16,
        [string]$FontFamily = 'Segoe UI',
        [int]$Width = 120,
        [string]$Margin = '0,0,0,0',
        [string]$BorderBrush = 'Black',
        [string]$BorderThickness = '1.65'
    )
    
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $Content
    $button.Background = $Background
    $button.Foreground = $Foreground
    $button.FontSize = $FontSize
    $button.FontFamily = $FontFamily
    $button.Width = $Width
    $button.Margin = $Margin
    $button.BorderBrush = $BorderBrush
    $button.BorderThickness = $BorderThickness
    $button.Template = [System.Windows.Markup.XamlReader]::Parse((Get-ButtonTemplate))
    
    return $button
}

function New-StyledTextBlock {
    param(
        [string]$Text,
        [int]$FontSize = 16,
        [string]$Foreground = 'White',
        [string]$FontFamily = 'Segoe UI',
        [string]$Margin = '0,0,0,12',
        [string]$FontWeight = 'Normal',
        [string]$TextAlignment = 'Left'
    )
    
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $Text
    $textBlock.FontSize = $FontSize
    $textBlock.Foreground = $Foreground
    $textBlock.FontFamily = $FontFamily
    $textBlock.Margin = $Margin
    $textBlock.FontWeight = $FontWeight
    if ($TextAlignment -ne 'Left') {
        $textBlock.TextAlignment = $TextAlignment
    }
    
    return $textBlock
}

# XAML for the window
$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='Sunrise Computers' Height='519' Width='990'
        WindowStyle='None' AllowsTransparency='True' Background='Transparent'>
    <Grid>
        <!-- Main background: rounded rectangle with custom gradient fill -->
        <Rectangle RadiusX='16' RadiusY='16' StrokeThickness='0'>
            <Rectangle.Fill>
                <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
                    <GradientStop Color='#000000' Offset='0'/>
                    <GradientStop Color='#000000' Offset='0.55'/>
                    <GradientStop Color='#FF6F00' Offset='1'/>
                </LinearGradientBrush>
            </Rectangle.Fill>
        </Rectangle>
        <!-- Main content -->
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width='320'/>
                <ColumnDefinition Width='*'/>
            </Grid.ColumnDefinitions>
            <!-- Custom Title Bar -->
            <Border x:Name='TitleBar' Grid.ColumnSpan='2' Height='40' VerticalAlignment='Top' Background='#000000' CornerRadius='16,16,0,0'>
                <Grid>
                    <!-- Logo on the left -->
                    <StackPanel Orientation='Horizontal' HorizontalAlignment='Left' VerticalAlignment='Center' Margin='10,0,0,0'>
                        <Image x:Name='LogoImage' Width='32' Height='32' Margin='0,0,10,0' VerticalAlignment='Center' RenderOptions.BitmapScalingMode='HighQuality'/>
                        <TextBlock Text='Sunrise Computers' FontSize='16' Foreground='#FFFFFF' FontFamily='Segoe UI' FontWeight='Bold' VerticalAlignment='Center'/>
                    </StackPanel>
                    <!-- Control buttons on the right -->
                    <StackPanel Orientation='Horizontal' HorizontalAlignment='Right' VerticalAlignment='Center' Margin='0,0,10,0'>
                        <Button x:Name='MaxBtn' Width='36' Height='28' Background='Transparent' BorderThickness='0' ToolTip='Maximize'>
                            <TextBlock Text='[ ]' FontSize='16' Foreground='White' FontFamily='Segoe UI' HorizontalAlignment='Center' VerticalAlignment='Center'/>
                        </Button>
                        <Button x:Name='CloseBtn' Width='36' Height='28' Background='Transparent' BorderThickness='0' ToolTip='Close'>
                            <TextBlock Text='X' FontSize='16' Foreground='White' FontFamily='Segoe UI' HorizontalAlignment='Center' VerticalAlignment='Center'/>
                        </Button>
                    </StackPanel>
                </Grid>
            </Border>
            <!-- Left Panel: semi-transparent black floating box -->
            <Border x:Name='LeftPanelMenu' Grid.Column='0' Margin='16,56,16,16' CornerRadius='12' Background='#000000' BorderBrush='Transparent' BorderThickness='0' Opacity='0.65'>
                <StackPanel VerticalAlignment='Top' Margin='24,32,0,0'>
                    <TextBlock Text='Select a Category' FontSize='24' FontWeight='Bold' Foreground='White' Margin='0,0,0,24' FontFamily='Segoe UI'/>
                    <TextBlock Text='1. General Tweaks' FontSize='18' Foreground='White' Margin='0,0,0,12' FontFamily='Segoe UI'/>
                    <TextBlock Text='2. Network' FontSize='18' Foreground='White' Margin='0,0,0,12' FontFamily='Segoe UI'/>
                    <TextBlock Text='3. Device Info' FontSize='18' Foreground='White' FontFamily='Segoe UI'/>
                </StackPanel>
            </Border>
            <!-- Right Panel: semi-transparent black floating box with scroll functionality -->
            <Border x:Name='RightPanelDesc' Grid.Column='1' Margin='0,56,16,16' CornerRadius='16' Background='#000000' BorderBrush='Transparent' BorderThickness='0' Opacity='0.65'>
                <ScrollViewer VerticalScrollBarVisibility='Auto' HorizontalScrollBarVisibility='Disabled'>
                    <StackPanel VerticalAlignment='Top' Margin='48,24,48,48'>
                        <TextBlock Text='Welcome' FontSize='56' FontWeight='Bold' Foreground='White' Margin='0,0,0,2' FontFamily='Segoe UI' TextAlignment='Center'/>
                        <TextBlock Text='Sunrise Computers' FontSize='28' Foreground='#FF6F00' FontWeight='Bold' Margin='0,0,0,0' FontFamily='Segoe UI' TextAlignment='Center'/>
                        <TextBlock Text='Since 2001' FontSize='22' Foreground='#FF6F00' Margin='0,0,0,32' FontFamily='Segoe UI' TextAlignment='Center'/>
                        <TextBlock Text='Select a Category from the list:' FontSize='22' Foreground='White' FontFamily='Segoe UI'/>
                    </StackPanel>
                </ScrollViewer>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

# Parse the XAML

$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
$global:window = [Windows.Markup.XamlReader]::Load($reader)

# Shared functions

# App Detection Functions for UI Integration
function global:Get-InstalledApps {
    $apps = @{}
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -and $_.UninstallString -and $_.SystemComponent -ne 1 -and
            $_.DisplayName -notmatch '^(Microsoft Visual C\+\+|Microsoft \.NET|Update for|Security Update|Hotfix|KB\d+)' -and
            $_.ReleaseType -ne "Security Update" -and $null -eq $_.ParentKeyName
        } | ForEach-Object {
            $cleanName = $_.DisplayName -replace '\s+\([^)]*\)$', ''
            $apps[$cleanName] = @{
                UninstallString = $_.UninstallString
                QuietUninstallString = $_.QuietUninstallString
                DisplayName = $_.DisplayName
                Type = "Registry"
            }
        }
    }
    return $apps
}

function global:Get-UWPApps {
    $apps = @{}
    try {
        # Get current user packages only - like Raphie's approach
        $packages = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notmatch '^(Microsoft\.Windows\.|Microsoft\.NET\.|Microsoft\.VCLibs|Microsoft\.UI\.Xaml|windows\.immersivecontrolpanel|Microsoft\.AAD\.BrokerPlugin|Microsoft\.AccountsControl)' -and
            -not $_.IsFramework -and $_.Status -eq "Ok" -and $_.SignatureKind -ne "System"
        }
        
        foreach ($package in $packages) {
            $displayName = if ($package.DisplayName) { $package.DisplayName } else { 
                $package.Name -replace '^Microsoft\.', '' -replace '\.', ' ' -replace 'App$', '' 
            }
            $apps[$displayName] = @{
                PackageName = $package.Name
                PackageFullName = $package.PackageFullName
                DisplayName = $displayName
                Publisher = $package.Publisher
                Type = "UWP"
            }
        }
    } catch { 
        Write-Warning "Failed to get UWP apps: $_" 
    }
    return $apps
}

function global:Get-AllInstalledApps {
    $allApps = global:Get-InstalledApps
    $uwpApps = global:Get-UWPApps
    foreach ($app in $uwpApps.GetEnumerator()) {
        $allApps[$app.Key] = $app.Value
    }
    return $allApps
}

function global:Show-PerformanceTweaks {
    param($rightPanelStack)
    # If rightPanelStack is actually the Border, get the StackPanel through ScrollViewer
    if ($rightPanelStack.GetType().Name -eq 'Border') {
        $scrollViewer = $rightPanelStack.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
        }
    }
    
    $rightPanelStack.Children.Clear()
    
    # Add title
    $titleBlock = New-Object System.Windows.Controls.TextBlock
    $titleBlock.Text = 'Performance Tweaks'
    $titleBlock.FontSize = 20
    $titleBlock.FontWeight = 'Bold'
    $titleBlock.Foreground = '#FF6F00'
    $titleBlock.FontFamily = 'Segoe UI'
    $titleBlock.Margin = '0,0,0,16'
    $rightPanelStack.Children.Add($titleBlock)
    
    # Add description
    $descBlock = New-Object System.Windows.Controls.TextBlock
    $descBlock.Text = 'This will automatically apply the following Windows performance optimizations:

- Disable Snap Assist Flyout
- Delete Temporary Files
- Disable Consumer Features
- Disable Telemetry
- Disable Activity History
- Disable Explorer Automatic Folder Discovery
- Disable GameDVR
- Disable Homegroup
- Disable Location Tracking
- Disable Storage Sense
- Disable Wi-Fi Sense
- Enable End Task With Right Click
- Set Services to Manual
- Enable Dark Mode
- Set Classic Right-Click Menu

These tweaks will enhance system responsiveness, improve startup times, and optimize various Windows settings for better performance.'
    $descBlock.FontSize = 14
    $descBlock.Foreground = 'White'
    $descBlock.FontFamily = 'Segoe UI'
    $descBlock.TextWrapping = 'Wrap'
    $descBlock.Margin = '0,0,0,16'
    $rightPanelStack.Children.Add($descBlock)
    
    # Add warning message
    $warningBlock = New-Object System.Windows.Controls.TextBlock
    $warningBlock.Text = 'Note: This will automatically apply ALL performance tweaks. The process will take a few minutes and requires administrator privileges.'
    $warningBlock.FontSize = 12
    $warningBlock.Foreground = '#FFD700'
    $warningBlock.FontFamily = 'Segoe UI'
    $warningBlock.TextWrapping = 'Wrap'
    $warningBlock.Margin = '0,0,0,24'
    $rightPanelStack.Children.Add($warningBlock)
    
    # Add run button
    $runBtn = New-StyledButton -Content 'Run Script' -FontSize 16 -Width 120
    $runBtn.Height = 40
    
    $runBtn.Add_Click({
        try {
            # Execute the script without any arguments (auto mode)
            Invoke-GitHubScript 'Perfomance_Tweaks.ps1'
            Write-Host "Performance tweaks applied successfully."
            [System.Windows.MessageBox]::Show("All performance tweaks have been applied successfully!", "Performance Tweaks Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            Write-Host "Error applying performance tweaks: $($_.Exception.Message)" -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Error applying performance tweaks: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })
    
    $rightPanelStack.Children.Add($runBtn)
}

function global:Show-AppRemovalSelection {
    param($rightPanelStack)
    # If rightPanelStack is actually the Border, get the StackPanel through ScrollViewer
    if ($rightPanelStack.GetType().Name -eq 'Border') {
        $scrollViewer = $rightPanelStack.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
        }
    }
    
    $rightPanelStack.Children.Clear()
    
    # Add title
    $titleBlock = New-Object System.Windows.Controls.TextBlock
    $titleBlock.Text = 'Remove Bloatware Applications'
    $titleBlock.FontSize = 20
    $titleBlock.FontWeight = 'Bold'
    $titleBlock.Foreground = '#FF6F00'
    $titleBlock.FontFamily = 'Segoe UI'
    $titleBlock.Margin = '0,0,0,16'
    $rightPanelStack.Children.Add($titleBlock)
    
    # Add description
    $descBlock = New-Object System.Windows.Controls.TextBlock
    $descBlock.Text = 'Select the applications you want to remove from your system. This will help free up disk space and improve system performance by removing unnecessary software.'
    $descBlock.FontSize = 14
    $descBlock.Foreground = 'White'
    $descBlock.FontFamily = 'Segoe UI'
    $descBlock.TextWrapping = 'Wrap'
    $descBlock.Margin = '0,0,0,12'
    $rightPanelStack.Children.Add($descBlock)
    
    # Add warning
    $warningBlock = New-Object System.Windows.Controls.TextBlock
    $warningBlock.Text = '⚠️ WARNING: Only remove apps that you know about. Don''t remove apps that you are not familiar with as they can disrupt some functionalities. If you accidentally remove them, then you can always download them back but you need to find them on your own.'
    $warningBlock.FontSize = 13
    $warningBlock.Foreground = '#FFEB3B'
    $warningBlock.FontFamily = 'Segoe UI'
    $warningBlock.FontWeight = 'Bold'
    $warningBlock.TextWrapping = 'Wrap'
    $warningBlock.Margin = '0,0,0,16'
    $rightPanelStack.Children.Add($warningBlock)
    
    # Add loading message
    $loadingText = New-StyledTextBlock -Text 'Loading installed applications...' -FontSize 16
    $rightPanelStack.Children.Add($loadingText)
    
    # Force UI update
    $global:window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
    
    try {
        # Get all installed apps
        $allApps = global:Get-AllInstalledApps
        $rightPanelStack.Children.Clear()
        
        # Re-add title, description, and warning after clearing
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = 'Remove Bloatware Applications'
        $titleBlock.FontSize = 20
        $titleBlock.FontWeight = 'Bold'
        $titleBlock.Foreground = '#FF6F00'
        $titleBlock.FontFamily = 'Segoe UI'
        $titleBlock.Margin = '0,0,0,16'
        $rightPanelStack.Children.Add($titleBlock)
        
        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = 'Select the applications you want to remove from your system. This will help free up disk space and improve system performance by removing unnecessary software.'
        $descBlock.FontSize = 14
        $descBlock.Foreground = 'White'
        $descBlock.FontFamily = 'Segoe UI'
        $descBlock.TextWrapping = 'Wrap'
        $descBlock.Margin = '0,0,0,12'
        $rightPanelStack.Children.Add($descBlock)
        
        $warningBlock = New-Object System.Windows.Controls.TextBlock
        $warningBlock.Text = "WARNING: Only remove apps that you know about. Don't remove apps that you are not familiar with as they can disrupt some functionalities.`nIf you accidentally remove them, then you can always download them back but you need to find them on your own."
        $warningBlock.FontSize = 13
        $warningBlock.Foreground = '#FFEB3B'
        $warningBlock.FontFamily = 'Segoe UI'
        $warningBlock.FontWeight = 'Bold'
        $warningBlock.TextWrapping = 'Wrap'
        $warningBlock.Margin = '0,0,0,16'
        $rightPanelStack.Children.Add($warningBlock)
        
        if ($allApps.Count -eq 0) {
            $noAppsText = New-StyledTextBlock -Text 'No removable applications found.' -FontSize 16
            $rightPanelStack.Children.Add($noAppsText)
            return
        }
        
        # Create apps container
        $appsBorder = New-Object System.Windows.Controls.Border
        $appsBorder.Background = '#FF2D2D30'
        $appsBorder.BorderBrush = '#FF3F3F46'
        $appsBorder.BorderThickness = '1'
        $appsBorder.CornerRadius = '4'
        $appsBorder.Margin = '0,0,0,16'
        $appsBorder.Padding = '12'
        
        $appsStack = New-Object System.Windows.Controls.StackPanel
        $appsStack.Orientation = 'Vertical'
        
        # Add subtitle within the container
        $subtitleText = New-Object System.Windows.Controls.TextBlock
        $subtitleText.Text = 'Select applications to remove:'
        $subtitleText.FontSize = 16
        $subtitleText.FontWeight = 'Bold'
        $subtitleText.Foreground = 'White'
        $subtitleText.FontFamily = 'Segoe UI'
        $subtitleText.Margin = '0,0,0,12'
        $appsStack.Children.Add($subtitleText)
        
        # Create checkboxes for each app
        $checkboxes = @()
        $sortedApps = $allApps.Keys | Sort-Object
        
        foreach ($appName in $sortedApps) {
            $app = $allApps[$appName]
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $appName
            $cb.ToolTip = "Type: $($app.Type)"
            if ($app.Publisher) {
                $cb.ToolTip += "`nPublisher: $($app.Publisher)"
            }
            $cb.Margin = '0,0,0,4'
            $cb.Foreground = 'White'
            $cb.FontFamily = 'Segoe UI'
            $cb.FontSize = 14
            $cb.Tag = $app  # Store app info in Tag for removal
            $checkboxes += $cb
            $appsStack.Children.Add($cb)
        }
        
        $appsBorder.Child = $appsStack
        $rightPanelStack.Children.Add($appsBorder)
        
        # Create button panel
        $buttonPanel = New-Object System.Windows.Controls.StackPanel
        $buttonPanel.Orientation = 'Horizontal'
        $buttonPanel.HorizontalAlignment = 'Left'
        $buttonPanel.Margin = '0,16,0,0'
        
        # Remove Selected button
        $removeBtn = New-StyledButton -Content 'Remove Selected Apps' -FontSize 16 -Background '#FF4444' -Width 180 -Margin '0,0,16,0'
        $removeBtn.Height = 40
        
        $removeBtn.Add_Click({
            # Find all checked checkboxes
            $selected = @()
            $rightPanelBorder = $global:window.FindName('RightPanelDesc')
            
            if ($rightPanelBorder -and $rightPanelBorder.Child -and $rightPanelBorder.Child.Content) {
                $stackPanel = $rightPanelBorder.Child.Content
                foreach ($child in $stackPanel.Children) {
                    if ($child -is [System.Windows.Controls.Border]) {
                        # Look inside the container for checkboxes
                        $containerStack = $child.Child
                        if ($containerStack) {
                            foreach ($containerChild in $containerStack.Children) {
                                if ($containerChild -is [System.Windows.Controls.CheckBox] -and $containerChild.IsChecked) {
                                    $selected += $containerChild
                                }
                            }
                        }
                    }
                }
            }
            
            if ($selected.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Please select at least one app to remove.", "No Apps Selected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                return
            }
            
            global:Remove-SelectedApps $selected $rightPanelBorder
            
            if ($rightPanelBorder -and $rightPanelBorder.Child -and $rightPanelBorder.Child.Content) {
                $stackPanel = $rightPanelBorder.Child.Content
                foreach ($child in $stackPanel.Children) {
                    if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked) {
                        $selected += $child
                    }
                }
            }
            
            if ($selected.Count -eq 0) {
                [System.Windows.MessageBox]::Show("No applications selected. Please select at least one application to remove.", "No Selection", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                return
            }
            
            # Confirm removal
            $result = [System.Windows.MessageBox]::Show("Are you sure you want to remove $($selected.Count) selected application(s)?`n`nThis action cannot be undone.", "Confirm Removal", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                global:Remove-SelectedApps $selected $rightPanelBorder
            }
        }.GetNewClosure())
        
        # Select All button
        $selectAllBtn = New-StyledButton -Content 'Select All' -FontSize 16 -Background '#444444' -Width 120 -Margin '0,0,16,0'
        $selectAllBtn.Height = 40
        
        $selectAllBtn.Add_Click({
            foreach ($cb in $checkboxes) {
                $cb.IsChecked = $true
            }
        }.GetNewClosure())
        
        # Clear All button
        $clearAllBtn = New-StyledButton -Content 'Clear All' -FontSize 16 -Background '#444444' -Width 120
        $clearAllBtn.Height = 40
        
        $clearAllBtn.Add_Click({
            foreach ($cb in $checkboxes) {
                $cb.IsChecked = $false
            }
        }.GetNewClosure())
        
        $buttonPanel.Children.Add($removeBtn)
        $buttonPanel.Children.Add($selectAllBtn)
        $buttonPanel.Children.Add($clearAllBtn)
        $rightPanelStack.Children.Add($buttonPanel)
        
    } catch {
        $rightPanelStack.Children.Clear()
        $errorText = New-StyledTextBlock -Text "Error loading applications: $($_.Exception.Message)" -FontSize 16 -Foreground 'Red'
        $rightPanelStack.Children.Add($errorText)
    }
}

function global:Remove-SelectedApps {
    param ([array]$SelectedCheckboxes, $rightPanelBorder)
    
    # Get the stack panel for progress updates
    if ($rightPanelBorder -and $rightPanelBorder.Child -and $rightPanelBorder.Child.Content) {
        $rightPanelStack = $rightPanelBorder.Child.Content
    } else {
        Write-Host "Could not find right panel for progress updates"
        return
    }
    
    # Clear the panel and show progress
    $rightPanelStack.Children.Clear()
    
    # Add progress title
    $progressTitle = New-StyledTextBlock -Text 'Removing Applications...' -FontSize 18 -FontWeight 'Bold' -Margin '0,0,0,16'
    $rightPanelStack.Children.Add($progressTitle)
    
    # Add progress text area
    $progressText = New-Object System.Windows.Controls.TextBlock
    $progressText.FontSize = 14
    $progressText.Foreground = 'White'
    $progressText.FontFamily = 'Consolas'
    $progressText.Text = "Starting app removal...`n"
    $progressText.TextWrapping = 'Wrap'
    $rightPanelStack.Children.Add($progressText)
    
    # Force UI update
    $global:window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
    
    $removed = $failed = 0
    $totalApps = $SelectedCheckboxes.Count
    
    foreach ($checkbox in $SelectedCheckboxes) {
        $appInfo = $checkbox.Tag  # App info stored in Tag
        $appName = $checkbox.Content
        
        # Update progress
        $progressText.Text += "Attempting to remove $appName...`n"
        $global:window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
        
        try {
            if ($appInfo.Type -eq "UWP") {
                # UWP app removal
                $appPattern = '*' + $appInfo.PackageName + '*'
                $success = $false
                
                # Remove for current user first
                try {
                    Get-AppxPackage -Name $appPattern | Remove-AppxPackage -ErrorAction Stop
                    $progressText.Text += "  Removed for current user`n"
                    $success = $true
                } catch {
                    $progressText.Text += "  Warning: Could not remove for current user`n"
                }
                
                # Remove for all users (requires admin)
                try {
                    Get-AppxPackage -Name $appPattern -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Stop
                    $progressText.Text += "  Removed for all users`n"
                    $success = $true
                } catch {
                    $progressText.Text += "  Warning: Could not remove for all users`n"
                }
                
                # Remove provisioned package
                try {
                    Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $appPattern } | ForEach-Object { 
                        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop
                    }
                    $progressText.Text += "  Removed provisioned package`n"
                } catch {
                    # Silent failure for provisioned packages
                }
                
                if ($success) {
                    $progressText.Text += "Successfully removed $appName`n`n"
                    $removed++
                } else {
                    $progressText.Text += "Failed to remove $appName`n`n"
                    $failed++
                }
                
            } else {
                # Registry app removal
                $uninstallCmd = if ($appInfo.QuietUninstallString) { $appInfo.QuietUninstallString } else { $appInfo.UninstallString }
                $success = $false
                
                if ($uninstallCmd -match 'msiexec.*(/I|/X)\s*(\{[^}]+\})') {
                    # MSI uninstall
                    $productCode = $matches[2]
                    try {
                        $process = Start-Process "msiexec.exe" -ArgumentList "/X$productCode", "/quiet", "/norestart" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1605 -or $process.ExitCode -eq 3010) {
                            $progressText.Text += "Successfully removed $appName`n`n"
                            $removed++
                            $success = $true
                        } else {
                            $progressText.Text += "Failed to remove $appName (Exit code: $($process.ExitCode))`n`n"
                            $failed++
                        }
                    } catch {
                        $progressText.Text += "Exception removing $appName`: $($_.Exception.Message)`n`n"
                        $failed++
                    }
                } elseif ($uninstallCmd -match '^"?([^"]+\.exe)"?\s*(.*)') {
                    # EXE uninstall
                    $exePath = $matches[1]
                    $arguments = $matches[2].Trim()
                    
                    if ($arguments -notmatch '(/S|/silent|/quiet|--silent)') { 
                        $arguments = "$arguments /S".Trim()
                    }
                    
                    try {
                        if (Test-Path $exePath) {
                            $process = Start-Process $exePath -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                            if ($process.ExitCode -eq 0) {
                                $progressText.Text += "Successfully removed $appName`n`n"
                                $removed++
                                $success = $true
                            } else {
                                $progressText.Text += "Failed to remove $appName (Exit code: $($process.ExitCode))`n`n"
                                $failed++
                            }
                        } else {
                            $progressText.Text += "Uninstaller not found for $appName`n`n"
                            $failed++
                        }
                    } catch {
                        $progressText.Text += "Exception removing $appName`: $($_.Exception.Message)`n`n"
                        $failed++
                    }
                } else {
                    $progressText.Text += "Unknown uninstall format for $appName`n`n"
                    $failed++
                }
            }
            
        } catch {
            $progressText.Text += "Exception removing $appName`: $($_.Exception.Message)`n`n"
            $failed++
        }
        
        # Force UI update after each app
        $global:window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
    }
    
    # Add summary
    $progressText.Text += "`n--- App Removal Summary ---`n"
    $progressText.Text += "Successfully removed: $removed`n"
    $progressText.Text += "Failed to remove: $failed`n"
    $progressText.Text += "Total apps processed: $($removed + $failed)/$totalApps`n"
    
    if ($removed -gt 0) {
        $progressText.Text += "`nApp removal completed!`n"
        $progressText.Text += "Note: Some changes may require a restart.`n"
    }
    
    # Add Done button
    $doneBtn = New-StyledButton -Content 'Done' -FontSize 16 -Margin '0,16,0,0'
    $doneBtn.HorizontalAlignment = 'Center'
    $doneBtn.Add_Click({
        # Clear the right panel to go back to main menu
        $rightPanelBorder = $global:window.FindName('RightPanelDesc')
        if ($rightPanelBorder -and $rightPanelBorder.Child -and $rightPanelBorder.Child.Content) {
            $rightPanelBorder.Child.Content.Children.Clear()
        }
    }.GetNewClosure())
    
    $rightPanelStack.Children.Add($doneBtn)
    
    # Force final UI update
    $global:window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
}

function Add-MenuItem {
    param($leftPanelStack, $text, $scriptName)
    $item = New-Object System.Windows.Controls.TextBlock
    $item.Text = $text
    $item.FontSize = 18
    $item.Foreground = 'White'
    $item.FontFamily = 'Segoe UI'
    $item.Margin = '0,0,0,12'
    $item.TextWrapping = 'Wrap'
    $item.Cursor = [System.Windows.Input.Cursors]::Hand
    $item.Add_MouseLeftButtonUp({
        try {
            if ($scriptName -eq 'Online-app-Install.ps1') {
                # Special handling for Online-app-Install.ps1 - directly show app selection
                global:Show-AppSelection
            } elseif ($scriptName -eq 'Perfomance_Tweaks.ps1') {
                $rightPanelBorder = $global:window.FindName('RightPanelDesc')
                if ($rightPanelBorder) {
                    global:Show-PerformanceTweaks $rightPanelBorder
                }
            } elseif ($scriptName -eq 'App_Remover.ps1') {
                $rightPanelBorder = $global:window.FindName('RightPanelDesc')
                if ($rightPanelBorder) {
                    global:Show-AppRemovalSelection $rightPanelBorder
                }
            } elseif ($scriptName) {
                # Show description and run button for the selected script
                global:Show-ScriptDescription $text $scriptName
            } elseif ($text -like 'A. Run All*') {
                global:Show-RunAllOption
            } elseif ($text -eq '1. General Tweaks') {
                global:Show-GeneralTweaksMenu
            } elseif ($text -eq '2. Network') {
                global:Show-NetworkMenu
            } elseif ($text -eq '3. Device Info') {
                global:Show-HardwareMenu
            } elseif ($text -eq '2. Install Apps (Online)') {
                # Directly show app selection instead of script description
                global:Show-AppSelection
            }
        } catch {
            [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", "Debug Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }.GetNewClosure())
    $leftPanelStack.Children.Add($item)
}

function global:Show-ScriptDescription {
    param($menuText, $scriptName)
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
        
        # Get description based on script
        $description = switch ($scriptName) {
            'Winget_Install.ps1' { "This script installs the Windows Package Manager (winget) on your system.`n If Winget is already installed then it will be updated to the latest version.`n We recommend using this script to ensure you have the latest version of winget,`n as it will provide the best experience when running other tweaks." }
            'Online-app-Install.ps1' { "Select applications to install from a curated list of popular software.`n This script will automate the installation process for you." }
            'Delay-WindowsUpdates.ps1' { "Delay Windows Updates`n`nThis script will configure Windows Update settings to delay automatic updates, giving you more control over when updates are installed.`n`nFeatures:`n- Prevent automatic restarts`n- Allow manual update installation`n- Maintain security while reducing interruptions" }
            'App_Remover.ps1' { "This will Provide you with a list of installed applications and allow you to select which ones to remove." }
            'Lanman_Network.ps1' { "Lanman Network Tweaks`n`nThis script configures LanmanWorkstation registry settings and SMB client configuration to enable secure guest authentication and insecure guest logons.`n`nWhat it does:`n- Enables AllowInsecureGuestAuth registry setting`n- Disables SMB security signature requirements`n- Enables insecure guest logons for SMB shares`n- Improves compatibility with older network devices`n`nNote: These changes reduce security but may be needed for legacy network access." }
            'SMB-Connection-Reset.ps1' { "Reset SMB Connections`n`nThis comprehensive network management script displays network adapter information, shows active SMB connections, and provides the option to reset all SMB connections by restarting the LanmanWorkstation service.`n`nFeatures:`n- Display network adapter link speeds and status`n- Show all active SMB protocol connections`n- Reset SMB connections (requires confirmation)`n- Restart LanmanWorkstation service safely`n- Requires administrator privileges for service operations" }
            'link-speed.ps1' { "Ethernet Link Speed Information`n`nThis simple diagnostic script displays detailed information about all network adapters on your system, including their current link speeds, status, and interface descriptions.`n`nInformation displayed:`n- Network adapter names and descriptions`n- Current connection status (Connected/Disconnected)`n- Link speed (e.g., 1 Gbps, 100 Mbps)`n- Interface details for troubleshooting`n`nUseful for diagnosing network performance issues and verifying adapter speeds." }
            'Hardware_Report_Generator.ps1' { "Hardware Information Report Generator`n`nThis comprehensive diagnostic script generates a detailed hardware report for your system and saves it to your desktop.`n`nReport includes:`n- System specifications (CPU, RAM, Storage)`n- Hardware component details`n- System boot type (UEFI/Legacy BIOS)`n- XMP memory profile status`n- Graphics adapter information`n- System temperatures and performance data`n`nThe report is automatically saved to your desktop with a timestamped filename for easy reference." }
            default { "Script: $scriptName`n`nThis script will perform system optimization tasks. Click 'Run Script' to execute it with administrator privileges." }
        }
        
        # Add description text
        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = $description
        $descBlock.FontSize = 16
        $descBlock.Foreground = 'White'
        $descBlock.FontFamily = 'Segoe UI'
        $descBlock.Margin = '0,0,0,20'
        $descBlock.TextWrapping = 'Wrap'
        $rightPanelStack.Children.Add($descBlock)
        
        # Add Run Script button
        $runBtn = New-StyledButton -Content 'Run Script' -FontSize 18 -Width 150
        $runBtn.Height = 40
        $runBtn.HorizontalAlignment = 'Left'
        
        # Store the script info as button properties
        $runBtn.Tag = @{
            ScriptName = $scriptName
            MenuText = $menuText
        }
        
        $runBtn.Add_Click({
            $buttonData = $this.Tag
            $scriptName = $buttonData.ScriptName
            
            # Special handling for link-speed.ps1 to show results in UI
            if ($scriptName -eq 'link-speed.ps1') {
                global:Show-LinkSpeedResults
                return
            }
            
            # Special handling for Hardware_Report_Generator.ps1 to show results in UI
            if ($scriptName -eq 'Hardware_Report_Generator.ps1') {
                global:Show-HardwareResults
                return
            }
            
            # Special handling for Online-app-Install.ps1 to show app selection UI
            if ($scriptName -eq 'Online-app-Install.ps1') {
                global:Show-AppSelection
                return
            }
            
            # Special handling for Lanman_Network.ps1 to show results in UI
            if ($scriptName -eq 'Lanman_Network.ps1') {
                # Run the UI function (already running as admin)
                global:Show-LanmanResults
                return
            }
            
            $scriptUrl = Get-GitHubScriptUrl $scriptName
            if ($scriptUrl) {
                try {
                    # Execute script from GitHub and show results
                    global:Show-ScriptResults $scriptName $buttonData.MenuText
                } catch {
                    [System.Windows.MessageBox]::Show("Error executing script: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            } else {
                [System.Windows.MessageBox]::Show("Script not available from GitHub: $scriptName", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        })
        $rightPanelStack.Children.Add($runBtn)
        }
    }
}

function global:Show-RunAllOption {
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
        
        # Add description for Run All
        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = "Run All General Tweaks Scripts`n`nThis option will execute all General Tweaks scripts in sequence:`n`n1. Install Winget (Package Manager)`n2. Install Common Applications`n3. Apply Performance Tweaks (automatically)`n4. Delay Windows Updates`n5. Remove Bloatware Applications`n`nThis process may take several minutes and will require administrator privileges. Each script will run one after another automatically."
        $descBlock.FontSize = 16
        $descBlock.Foreground = 'White'
        $descBlock.FontFamily = 'Segoe UI'
        $descBlock.Margin = '0,0,0,20'
        $descBlock.TextWrapping = 'Wrap'
        $rightPanelStack.Children.Add($descBlock)
        
        # Add Run All button
        $runAllBtn = New-StyledButton -Content 'Run All Scripts' -FontSize 18 -Width 180
        $runAllBtn.Height = 40
        $runAllBtn.HorizontalAlignment = 'Left'
        $runAllBtn.Add_Click({
            # Run scripts in sequence (already running as admin)
            $scripts = @('Winget_Install.ps1', 'Online-app-Install.ps1', 'Delay-WindowsUpdates.ps1', 'App_Remover.ps1')
            $failedScripts = @()
            
            foreach ($script in $scripts) {
                try {
                    # Execute directly from GitHub (already admin)
                    Invoke-GitHubScript $script
                } catch {
                    $failedScripts += $script
                    Write-Host "Failed to execute: $script"
                }
            }
            
            # Log completion status
            if ($failedScripts.Count -eq 0) {
                Write-Host "All scripts have been executed successfully."
            } else {
                Write-Host "Some scripts failed or were not found:"
                $failedScripts | ForEach-Object { Write-Host "  - $_" }
            }
        })
        $rightPanelStack.Children.Add($runAllBtn)
        }
    }
}

function global:Show-MainMenu {
    $leftPanelBorder = $global:window.FindName('LeftPanelMenu')
    if ($leftPanelBorder -and $leftPanelBorder.Child) {
        $leftPanelStack = $leftPanelBorder.Child
        $leftPanelStack.Children.Clear()
        
        # Add category title
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = 'Select a Category'
        $titleBlock.FontSize = 24
        $titleBlock.FontWeight = 'Bold'
        $titleBlock.Foreground = 'White'
        $titleBlock.Margin = '0,0,0,24'
        $titleBlock.FontFamily = 'Segoe UI'
        $leftPanelStack.Children.Add($titleBlock)
        
        # Add main menu items
        Add-MenuItem $leftPanelStack '1. General Tweaks' ''
        Add-MenuItem $leftPanelStack '2. Network' ''
        Add-MenuItem $leftPanelStack '3. Device Info' ''
    }
    
    # Show welcome message in right panel
    Show-WelcomePanel
}

function global:Show-WelcomePanel {
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
            
            # Add welcome content
            $welcomeTitle = New-Object System.Windows.Controls.TextBlock
            $welcomeTitle.Text = 'Welcome'
            $welcomeTitle.FontSize = 56
            $welcomeTitle.FontWeight = 'Bold'
            $welcomeTitle.Foreground = 'White'
            $welcomeTitle.Margin = '0,0,0,2'
            $welcomeTitle.FontFamily = 'Segoe UI'
            $welcomeTitle.TextAlignment = 'Center'
            $rightPanelStack.Children.Add($welcomeTitle)
            
            $companyTitle = New-Object System.Windows.Controls.TextBlock
            $companyTitle.Text = 'Sunrise Computers'
            $companyTitle.FontSize = 28
            $companyTitle.Foreground = '#FF6F00'
            $companyTitle.FontWeight = 'Bold'
            $companyTitle.Margin = '0,0,0,0'
            $companyTitle.FontFamily = 'Segoe UI'
            $companyTitle.TextAlignment = 'Center'
            $rightPanelStack.Children.Add($companyTitle)
            
            $instructionTitle = New-Object System.Windows.Controls.TextBlock
            $instructionTitle.Text = 'Select a Category from the list on the left to get started.'
            $instructionTitle.FontSize = 22
            $instructionTitle.Foreground = 'White'
            $instructionTitle.FontFamily = 'Segoe UI'
            $rightPanelStack.Children.Add($instructionTitle)
        }
    }
}

function global:Show-SubMenu {
    param(
        [string]$MenuTitle,
        [hashtable]$MenuItems,
        [string]$RightPanelDescription
    )
    
    $leftPanelBorder = $global:window.FindName('LeftPanelMenu')
    if ($leftPanelBorder -and $leftPanelBorder.Child) {
        $leftPanelStack = $leftPanelBorder.Child
        $leftPanelStack.Children.Clear()
        
        # Add back button
        $backBtn = New-Object System.Windows.Controls.TextBlock
        $backBtn.Text = '<-- Back to Main Menu'
        $backBtn.FontSize = 16
        $backBtn.Foreground = '#FF6F00'
        $backBtn.FontFamily = 'Segoe UI'
        $backBtn.Margin = '0,0,0,20'
        $backBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        $backBtn.Add_MouseLeftButtonUp({
            global:Show-MainMenu
        })
        $leftPanelStack.Children.Add($backBtn)
        
        # Add section title
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = $MenuTitle
        $titleBlock.FontSize = 24
        $titleBlock.FontWeight = 'Bold'
        $titleBlock.Foreground = 'White'
        $titleBlock.Margin = '0,0,0,16'
        $titleBlock.FontFamily = 'Segoe UI'
        $leftPanelStack.Children.Add($titleBlock)
        
        # Add menu items dynamically
        foreach ($key in $MenuItems.Keys | Sort-Object) {
            $item = $MenuItems[$key]
            $displayText = "$key. $($item.Name)"
            Add-MenuItem $leftPanelStack $displayText $item.File
        }
    }
    Show-SubMenuRightPanel $RightPanelDescription
}

function global:Show-SubMenuRightPanel {
    param([string]$Description)
    
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
            $rightPanelStack.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{Text=$Description; FontSize=18; Foreground='White'; FontFamily='Segoe UI'; Margin='0,0,0,12'}))
        }
    }
}

function global:Show-GeneralTweaksMenu {
    # Define General Tweaks menu items
    $menuItems = @{
        "1" = @{ Name = "Install WinGet"; File = "Winget_Install.ps1" }
        "2" = @{ Name = "Install Apps (Online)"; File = "Online-app-Install.ps1" }
        "3" = @{ Name = "Apply Performance Tweaks"; File = "Perfomance_Tweaks.ps1" }
        "4" = @{ Name = "Stop Automatic Windows Updates"; File = "Delay-WindowsUpdates.ps1" }
        "5" = @{ Name = "Remove Bloatware"; File = "App_Remover.ps1" }
        "A" = @{ Name = "Run All Scripts"; File = "" }
    }
    
    Show-SubMenu "General Tweaks" $menuItems "Select an option to perform General Tweaks tasks."
}

function global:Show-NetworkMenu {
    # Define Network menu items
    $menuItems = @{
        "6" = @{ Name = "Lanman Network Tweaks"; File = "Lanman_Network.ps1" }
        "7" = @{ Name = "Reset SMB Connection"; File = "SMB-Connection-Reset.ps1" }
        "8" = @{ Name = "Ethernet Link Speed"; File = "link-speed.ps1" }
    }

    Show-SubMenu "Network" $menuItems "Select a network option to configure network settings and`n connections."
}

function global:Show-HardwareMenu {
    # Define Hardware menu items
    $menuItems = @{
        "H" = @{ Name = "Hardware Information"; File = "Hardware_Report_Generator.ps1" }
    }
    
    Show-SubMenu "Hardware" $menuItems "Select a hardware option to view system information and generate`n reports."
}

function global:Show-LanmanResults {
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
            
            # Add title
            $titleBlock = New-Object System.Windows.Controls.TextBlock
            $titleBlock.Text = 'Lanman Network Configuration Results'
            $titleBlock.FontSize = 20
            $titleBlock.FontWeight = 'Bold'
            $titleBlock.Foreground = '#FF6F00'
            $titleBlock.FontFamily = 'Segoe UI'
            $titleBlock.Margin = '0,0,0,16'
            $rightPanelStack.Children.Add($titleBlock)
            
            $results = @()
            
            # Proceed with Lanman configuration (already running as admin)
            
            try {
                # Registry Configuration
                $results += "Registry Configuration:"
                
                # Set the location to the registry
                Set-Location -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows'
                
                # Create a new Key
                Get-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' | New-Item -Name 'LanmanWorkstation' -Force | Out-Null
                $results += "[OK] Created LanmanWorkstation registry key"
                
                # Create new items with values
                New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation' -Name 'AllowInsecureGuestAuth' -Value "1" -PropertyType DWORD -Force | Out-Null
                $results += "[OK] Set AllowInsecureGuestAuth = 1"
                
                # Get out of the Registry
                Pop-Location
                
                $results += ""
                $results += "SMB Client Configuration:"
                
                # To disable SMB signing requirement (auto-confirm)
                Set-SmbClientConfiguration -RequireSecuritySignature $false -Confirm:$false
                $results += "[OK] Disabled SMB security signature requirement"
                
                # To disable guest fallback (auto-confirm)
                Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Confirm:$false
                $results += "[OK] Enabled insecure guest logons"
                
                $results += ""
                $results += "Configuration completed successfully!"
                $results += "Note: These changes improve compatibility with older network devices but reduce security."
                
            } catch {
                $results += "[ERROR] Error: $($_.Exception.Message)"
            }
            
            # Display results
            foreach ($result in $results) {
                $resultBlock = New-Object System.Windows.Controls.TextBlock
                $resultBlock.Text = $result
                $resultBlock.FontSize = 14
                $resultBlock.FontFamily = 'Segoe UI'
                $resultBlock.Margin = '0,0,0,6'
                $resultBlock.TextWrapping = 'Wrap'
                
                if ($result -like "[OK]*") {
                    $resultBlock.Foreground = '#FF4CAF50'  # Green for success
                } elseif ($result -like "[ERROR]*") {
                    $resultBlock.Foreground = '#FFFF5722'  # Red for errors
                } elseif ($result -like "Note:*") {
                    $resultBlock.Foreground = '#FFFFEB3B'  # Yellow for warnings
                } elseif ($result -eq "" -or $result -like "*Configuration*" -or $result -like "*Results*") {
                    if ($result -ne "") {
                        $resultBlock.Foreground = '#FF03DAC6'  # Cyan for section headers
                        $resultBlock.FontWeight = 'Bold'
                    }
                } else {
                    $resultBlock.Foreground = 'White'
                }
                
                if ($result -ne "") {
                    $rightPanelStack.Children.Add($resultBlock)
                } else {
                    # Add spacing for empty lines
                    $spacer = New-Object System.Windows.Controls.TextBlock
                    $spacer.Height = 8
                    $rightPanelStack.Children.Add($spacer)
                }
            }
        }
    }
}

function global:Show-LinkSpeedResults {
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
            
            # Add title
            $titleBlock = New-Object System.Windows.Controls.TextBlock
            $titleBlock.Text = 'Network Adapter Information'
            $titleBlock.FontSize = 20
            $titleBlock.FontWeight = 'Bold'
            $titleBlock.Foreground = '#FF6F00'
            $titleBlock.FontFamily = 'Segoe UI'
            $titleBlock.Margin = '0,0,0,16'
            $rightPanelStack.Children.Add($titleBlock)
            
            try {
                # Get network adapter information
                $networkAdapters = Get-NetAdapter | Select-Object InterfaceDescription, Name, Status, LinkSpeed
                
                foreach ($adapter in $networkAdapters) {
                    # Create a border for each adapter
                    $border = New-Object System.Windows.Controls.Border
                    $border.Background = '#FF2D2D30'
                    $border.BorderBrush = '#FF3F3F46'
                    $border.BorderThickness = '1'
                    $border.CornerRadius = '4'
                    $border.Margin = '0,0,0,12'
                    $border.Padding = '12'
                    
                    $adapterStack = New-Object System.Windows.Controls.StackPanel
                    $adapterStack.Orientation = 'Vertical'
                    
                    # Adapter name
                    $nameBlock = New-Object System.Windows.Controls.TextBlock
                    $nameBlock.Text = "Name: $($adapter.Name)"
                    $nameBlock.FontSize = 16
                    $nameBlock.FontWeight = 'Bold'
                    $nameBlock.Foreground = 'White'
                    $nameBlock.FontFamily = 'Segoe UI'
                    $nameBlock.Margin = '0,0,0,6'
                    $adapterStack.Children.Add($nameBlock)
                    
                    # Interface description
                    $descBlock = New-Object System.Windows.Controls.TextBlock
                    $descBlock.Text = "Description: $($adapter.InterfaceDescription)"
                    $descBlock.FontSize = 14
                    $descBlock.Foreground = '#FFCCCCCC'
                    $descBlock.FontFamily = 'Segoe UI'
                    $descBlock.Margin = '0,0,0,4'
                    $descBlock.TextWrapping = 'Wrap'
                    $adapterStack.Children.Add($descBlock)
                    
                    # Status
                    $statusBlock = New-Object System.Windows.Controls.TextBlock
                    $statusBlock.Text = "Status: $($adapter.Status)"
                    $statusBlock.FontSize = 14
                    $statusBlock.FontFamily = 'Segoe UI'
                    $statusBlock.Margin = '0,0,0,4'
                    if ($adapter.Status -eq 'Up') {
                        $statusBlock.Foreground = '#FF4CAF50'  # Green
                    } else {
                        $statusBlock.Foreground = '#FFFF5722'  # Red
                    }
                    $adapterStack.Children.Add($statusBlock)
                    
                    # Link speed
                    $linkSpeedBlock = New-Object System.Windows.Controls.TextBlock
                    $linkSpeedText = if ($adapter.LinkSpeed) { $adapter.LinkSpeed } else { 'N/A' }
                    $linkSpeedBlock.Text = "Link Speed: $linkSpeedText"
                    $linkSpeedBlock.FontSize = 14
                    $linkSpeedBlock.Foreground = '#FF03DAC6'
                    $linkSpeedBlock.FontFamily = 'Segoe UI'
                    $linkSpeedBlock.Margin = '0,0,0,4'
                    $adapterStack.Children.Add($linkSpeedBlock)
                    
                    $border.Child = $adapterStack
                    $rightPanelStack.Children.Add($border)
                }
            } catch {
                $errorBlock = New-Object System.Windows.Controls.TextBlock
                $errorBlock.Text = "Error retrieving network adapter information: $($_.Exception.Message)"
                $errorBlock.FontSize = 14
                $errorBlock.Foreground = '#FFFF5722'
                $errorBlock.FontFamily = 'Segoe UI'
                $errorBlock.TextWrapping = 'Wrap'
                $rightPanelStack.Children.Add($errorBlock)
            }
        }
    }
}

function global:Show-HardwareResults {
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
            
            # Add title
            $titleBlock = New-Object System.Windows.Controls.TextBlock
            $titleBlock.Text = 'Hardware Report Generator'
            $titleBlock.FontSize = 20
            $titleBlock.FontWeight = 'Bold'
            $titleBlock.Foreground = '#FF6F00'
            $titleBlock.FontFamily = 'Segoe UI'
            $titleBlock.Margin = '0,0,0,16'
            $rightPanelStack.Children.Add($titleBlock)
            
            # Add status message
            $statusBlock = New-Object System.Windows.Controls.TextBlock
            $statusBlock.Text = 'Generating hardware report...'
            $statusBlock.FontSize = 16
            $statusBlock.Foreground = 'White'
            $statusBlock.FontFamily = 'Segoe UI'
            $statusBlock.Margin = '0,0,0,12'
            $rightPanelStack.Children.Add($statusBlock)
            
            try {
                # Run the hardware report script from GitHub and capture output
                $output = Invoke-GitHubScript 'Hardware_Report_Generator.ps1' 2>&1 | Out-String
                
                # Update status to show completion
                $statusBlock.Text = 'Hardware report generated successfully!'
                $statusBlock.Foreground = '#90EE90'  # Light green
                
                # Create result container
                $resultBorder = New-Object System.Windows.Controls.Border
                $resultBorder.Background = '#FF2D2D30'
                $resultBorder.BorderBrush = '#FF3F3F46'
                $resultBorder.BorderThickness = '1'
                $resultBorder.CornerRadius = '1'
                $resultBorder.Margin = '0,12,0,12'
                $resultBorder.Padding = '12'
                
                $resultStack = New-Object System.Windows.Controls.StackPanel
                $resultStack.Orientation = 'Vertical'
                
                # Parse output for success message and filename
                $fileName = ""
                $filePath = ""
                if ($output -match "File saved as: (.+)") {
                    $fileName = $matches[1].Trim()
                    $desktopPath = [Environment]::GetFolderPath('Desktop')
                    $filePath = Join-Path $desktopPath $fileName
                }
                
                # Success message
                $successBlock = New-Object System.Windows.Controls.TextBlock
                $successBlock.Text = "SUCCESS: Scan Report saved to DESKTOP!"
                $successBlock.FontSize = 16
                $successBlock.FontWeight = 'Bold'
                $successBlock.Foreground = '#90EE90'  # Light green
                $successBlock.FontFamily = 'Segoe UI'
                $successBlock.Margin = '0,0,0,8'
                $resultStack.Children.Add($successBlock)
                
                # File name block
                if ($fileName) {
                    $fileBlock = New-Object System.Windows.Controls.TextBlock
                    $fileBlock.Text = "File saved as: $fileName"
                    $fileBlock.FontSize = 14
                    $fileBlock.Foreground = '#87CEEB'  # Sky blue
                    $fileBlock.FontFamily = 'Segoe UI'
                    $fileBlock.Margin = '0,0,0,12'
                    $resultStack.Children.Add($fileBlock)
                }
                
                # Location info
                $locationBlock = New-Object System.Windows.Controls.TextBlock
                $locationBlock.Text = "Location: Desktop"
                $locationBlock.FontSize = 14
                $locationBlock.Foreground = 'White'
                $locationBlock.FontFamily = 'Segoe UI'
                $locationBlock.Margin = '0,0,0,8'
                $resultStack.Children.Add($locationBlock)
                
                # Open file button
                $openBtn = New-StyledButton -Content 'Open Report' -FontSize 14 -Width 150 -Margin '0,8,0,0'
                $openBtn.Add_Click({
                    if ($filePath -and (Test-Path $filePath)) {
                        Start-Process notepad $filePath
                    } else {
                        # Fallback to opening desktop folder if file not found
                        $desktopPath = [Environment]::GetFolderPath('Desktop')
                        Start-Process explorer $desktopPath
                    }
                }.GetNewClosure())
                $resultStack.Children.Add($openBtn)
                
                $resultBorder.Child = $resultStack
                $rightPanelStack.Children.Add($resultBorder)
                
            } catch {
                # Error handling
                $statusBlock.Text = 'Error generating hardware report'
                $statusBlock.Foreground = '#FF6B6B'  # Light red
                
                $errorBlock = New-Object System.Windows.Controls.TextBlock
                $errorBlock.Text = "Error: $($_.Exception.Message)"
                $errorBlock.FontSize = 14
                $errorBlock.Foreground = '#FF6B6B'
                $errorBlock.FontFamily = 'Segoe UI'
                $errorBlock.Margin = '0,12,0,0'
                $errorBlock.TextWrapping = 'Wrap'
                $rightPanelStack.Children.Add($errorBlock)
            }
        }
    }
}

function global:Show-ScriptResults {
    param(
        [string]$ScriptName,
        [string]$MenuText
    )
    
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
            
            # Add title
            $titleBlock = New-Object System.Windows.Controls.TextBlock
            $titleBlock.Text = "Executing: $MenuText"
            $titleBlock.FontSize = 20
            $titleBlock.FontWeight = 'Bold'
            $titleBlock.Foreground = '#FF6F00'
            $titleBlock.FontFamily = 'Segoe UI'
            $titleBlock.Margin = '0,0,0,16'
            $rightPanelStack.Children.Add($titleBlock)
            
            # Add status message
            $statusBlock = New-Object System.Windows.Controls.TextBlock
            $statusBlock.Text = 'Initializing script execution...'
            $statusBlock.FontSize = 16
            $statusBlock.Foreground = '#03DAC6'
            $statusBlock.FontFamily = 'Segoe UI'
            $statusBlock.Margin = '0,0,0,12'
            $rightPanelStack.Children.Add($statusBlock)
            
            # Create output container
            $outputBorder = New-Object System.Windows.Controls.Border
            $outputBorder.Background = '#FF1E1E1E'
            $outputBorder.BorderBrush = '#FF3F3F46'
            $outputBorder.BorderThickness = '1'
            $outputBorder.CornerRadius = '4'
            $outputBorder.Margin = '0,12,0,12'
            $outputBorder.Padding = '12'
            
            $outputStack = New-Object System.Windows.Controls.StackPanel
            $outputStack.Orientation = 'Vertical'
            
            # Script info
            $pathBlock = New-Object System.Windows.Controls.TextBlock
            $pathBlock.Text = "Script: $ScriptName (from GitHub)"
            $pathBlock.FontSize = 12
            $pathBlock.Foreground = '#87CEEB'
            $pathBlock.FontFamily = 'Consolas'
            $pathBlock.Margin = '0,0,0,8'
            $outputStack.Children.Add($pathBlock)
            
            # Separator
            $separatorBlock = New-Object System.Windows.Controls.TextBlock
            $separatorBlock.Text = "=" * 60
            $separatorBlock.FontSize = 12
            $separatorBlock.Foreground = '#666666'
            $separatorBlock.FontFamily = 'Consolas'
            $separatorBlock.Margin = '0,0,0,8'
            $outputStack.Children.Add($separatorBlock)
            
            try {
                # Update status
                $statusBlock.Text = 'Executing script from GitHub...'
                $statusBlock.Foreground = '#FFEB3B'
                
                # Execute script directly from GitHub (already running as admin)
                $output = Invoke-GitHubScript $ScriptName 2>&1 | Out-String
                
                # Process and display output
                $lines = $output -split "`n"
                foreach ($line in $lines) {
                    if ($line.Trim() -ne "") {
                        $outputLine = New-Object System.Windows.Controls.TextBlock
                        $outputLine.Text = $line
                        $outputLine.FontSize = 12
                        $outputLine.FontFamily = 'Consolas'
                        $outputLine.TextWrapping = 'Wrap'
                        $outputLine.Margin = '0,0,0,2'
                        
                        # Color code based on content
                        if ($line -match "ERROR|FAILED|Exception|Error:") {
                            $outputLine.Foreground = '#FF6B6B'  # Red for errors
                        } elseif ($line -match "SUCCESS|COMPLETED|OK|\[OK\]|Success!|Successfully|Complete") {
                            $outputLine.Foreground = '#4CAF50'  # Green for success
                        } elseif ($line -match "WARNING|WARN|\[WARNING\]") {
                            $outputLine.Foreground = '#FFC107'  # Yellow for warnings
                        } elseif ($line -match "Installing|Downloading|Processing|Current:|Method:|Build:|Version:") {
                            $outputLine.Foreground = '#03DAC6'  # Cyan for progress/info
                        } elseif ($line -match "Windows|PowerShell|WinGet|Latest") {
                            $outputLine.Foreground = '#87CEEB'  # Light blue for system info
                        } else {
                            $outputLine.Foreground = 'White'    # White for normal text
                        }
                        
                        $outputStack.Children.Add($outputLine)
                    }
                }
                
                # Final separator
                $finalSeparatorBlock = New-Object System.Windows.Controls.TextBlock
                $finalSeparatorBlock.Text = "=" * 60
                $finalSeparatorBlock.FontSize = 12
                $finalSeparatorBlock.Foreground = '#666666'
                $finalSeparatorBlock.FontFamily = 'Consolas'
                $finalSeparatorBlock.Margin = '0,8,0,8'
                $outputStack.Children.Add($finalSeparatorBlock)
                
                # Completion message
                $completionBlock = New-Object System.Windows.Controls.TextBlock
                $completionBlock.Text = "[OK] Script execution completed successfully!"
                $completionBlock.FontSize = 14
                $completionBlock.FontWeight = 'Bold'
                $completionBlock.Foreground = '#4CAF50'
                $completionBlock.FontFamily = 'Segoe UI'
                $completionBlock.Margin = '0,8,0,0'
                $outputStack.Children.Add($completionBlock)
                
                # Update status to show completion
                $statusBlock.Text = 'Script execution completed!'
                $statusBlock.Foreground = '#4CAF50'
                
            } catch {
                # Error handling
                $statusBlock.Text = 'Script execution failed!'
                $statusBlock.Foreground = '#FF6B6B'
                
                $errorBlock = New-Object System.Windows.Controls.TextBlock
                $errorBlock.Text = "[ERROR] $($_.Exception.Message)"
                $errorBlock.FontSize = 14
                $errorBlock.Foreground = '#FF6B6B'
                $errorBlock.FontFamily = 'Consolas'
                $errorBlock.Margin = '0,8,0,0'
                $errorBlock.TextWrapping = 'Wrap'
                $outputStack.Children.Add($errorBlock)
            }
            
            $outputBorder.Child = $outputStack
            $rightPanelStack.Children.Add($outputBorder)
        }
    }
}

function global:Show-AppSelection {
    $rightPanelBorder = $global:window.FindName('RightPanelDesc')
    if ($rightPanelBorder -and $rightPanelBorder.Child) {
        $scrollViewer = $rightPanelBorder.Child
        if ($scrollViewer -and $scrollViewer.Content) {
            $rightPanelStack = $scrollViewer.Content
            $rightPanelStack.Children.Clear()
            
            # Add title
            $titleBlock = New-Object System.Windows.Controls.TextBlock
            $titleBlock.Text = 'Select Apps to Install'
            $titleBlock.FontSize = 20
            $titleBlock.FontWeight = 'Bold'
            $titleBlock.Foreground = '#FF6F00'
            $titleBlock.FontFamily = 'Segoe UI'
            $titleBlock.Margin = '0,0,0,16'
            $rightPanelStack.Children.Add($titleBlock)
            
            # Add description
            $descBlock = New-Object System.Windows.Controls.TextBlock
            $descBlock.Text = 'Choose the applications you want to install using WinGet. Selected apps will be downloaded and installed automatically with all permissions accepted.'
            $descBlock.FontSize = 14
            $descBlock.Foreground = 'White'
            $descBlock.FontFamily = 'Segoe UI'
            $descBlock.TextWrapping = 'Wrap'
            $descBlock.Margin = '0,0,0,16'
            $rightPanelStack.Children.Add($descBlock)
            
            # Create app container
            $appBorder = New-Object System.Windows.Controls.Border
            $appBorder.Background = '#FF2D2D30'
            $appBorder.BorderBrush = '#FF3F3F46'
            $appBorder.BorderThickness = '1'
            $appBorder.CornerRadius = '4'
            $appBorder.Margin = '0,0,0,16'
            $appBorder.Padding = '12'
            
            $appStack = New-Object System.Windows.Controls.StackPanel
            $appStack.Orientation = 'Vertical'
            
            # Define available apps with better organization
            $apps = @(
                @{ Name = "Mozilla Firefox"; Id = "Mozilla.Firefox"; Description = "Popular web browser" },
                @{ Name = "Google Chrome"; Id = "Google.Chrome"; Description = "Fast web browser by Google" },
                @{ Name = "Microsoft Edge"; Id = "Microsoft.Edge"; Description = "Microsoft's modern web browser" },
                @{ Name = "7-Zip"; Id = "7zip.7zip"; Description = "File archiver with high compression ratio" },
                @{ Name = "WinRAR"; Id = "RARLab.WinRAR"; Description = "Archive manager for Windows" },
                @{ Name = "VLC Media Player"; Id = "VideoLAN.VLC"; Description = "Free multimedia player" },
                @{ Name = "Spotify"; Id = "Spotify.Spotify"; Description = "Music streaming service" },
                @{ Name = "Discord"; Id = "Discord.Discord"; Description = "Voice and text chat for gamers" },
                @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode"; Description = "Code editor by Microsoft" },
                @{ Name = "Notepad++"; Id = "Notepad++.Notepad++"; Description = "Advanced text editor" },
                @{ Name = "Adobe Acrobat Reader"; Id = "Adobe.Acrobat.Reader.64-bit"; Description = "PDF reader" },
                @{ Name = "SumatraPDF"; Id = "SumatraPDF.SumatraPDF"; Description = "Lightweight PDF reader" },
                @{ Name = "OBS Studio"; Id = "OBSProject.OBSStudio"; Description = "Free recording and streaming software" },
                @{ Name = "Steam"; Id = "Valve.Steam"; Description = "Gaming platform" },
                @{ Name = "TeamViewer"; Id = "TeamViewer.TeamViewer"; Description = "Remote desktop software" },
                @{ Name = "UltraViewer"; Id = "DucFabulous.UltraViewer"; Description = "Remote desktop tool" },
                @{ Name = "Zoom"; Id = "Zoom.Zoom"; Description = "Video conferencing software" },
                @{ Name = "WhatsApp"; Id = "WhatsApp.WhatsApp"; Description = "Messaging app" }
            )
            
            # Create checkboxes for each app
            $checkboxes = @()
            foreach ($app in $apps) {
                $checkbox = New-Object System.Windows.Controls.CheckBox
                $checkbox.Content = "$($app.Name) - $($app.Description)"
                $checkbox.FontSize = 12
                $checkbox.Foreground = 'White'
                $checkbox.FontFamily = 'Segoe UI'
                $checkbox.Margin = '0,4,0,4'
                $checkbox.Tag = $app
                $checkboxes += $checkbox
                $appStack.Children.Add($checkbox)
            }
            
            $appBorder.Child = $appStack
            $rightPanelStack.Children.Add($appBorder)
            
            # Add buttons container
            $buttonPanel = New-Object System.Windows.Controls.StackPanel
            $buttonPanel.Orientation = 'Horizontal'
            $buttonPanel.HorizontalAlignment = 'Left'
            $buttonPanel.Margin = '0,16,0,0'
            
            # Install Selected button
            $installBtn = New-StyledButton -Content 'Install Selected Apps' -FontSize 16 -Width 180 -Margin '0,0,16,0'
            $installBtn.Height = 40
            
            $installBtn.Add_Click({
                # Get selected apps
                $selectedApps = @()
                foreach ($cb in $checkboxes) {
                    if ($cb.IsChecked) {
                        $selectedApps += $cb.Tag
                    }
                }
                
                if ($selectedApps.Count -eq 0) {
                    [System.Windows.MessageBox]::Show("Please select at least one app to install.", "No Apps Selected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    return
                }
                
                # Start installation process
                global:Start-AppInstallation $selectedApps
            }.GetNewClosure())
            
            # Select All button
            $selectAllBtn = New-StyledButton -Content 'Select All' -FontSize 16 -Background '#444444' -Width 120 -Margin '0,0,16,0'
            $selectAllBtn.Height = 40
            
            $selectAllBtn.Add_Click({
                foreach ($cb in $checkboxes) {
                    $cb.IsChecked = $true
                }
            }.GetNewClosure())
            
            # Clear All button
            $clearAllBtn = New-StyledButton -Content 'Clear All' -FontSize 16 -Background '#444444' -Width 120
            $clearAllBtn.Height = 40
            
            $clearAllBtn.Add_Click({
                foreach ($cb in $checkboxes) {
                    $cb.IsChecked = $false
                }
            }.GetNewClosure())
            
            $buttonPanel.Children.Add($installBtn)
            $buttonPanel.Children.Add($selectAllBtn)
            $buttonPanel.Children.Add($clearAllBtn)
            $rightPanelStack.Children.Add($buttonPanel)
        }
    }
}

function global:Start-AppInstallation {
    param([array]$SelectedApps)
    
    # Use a much simpler approach - create the script line by line using simple string operations
    $lines = @()
    $lines += '# App Installation Script'
    $lines += 'Write-Host "=== Installing Selected Apps ===" -ForegroundColor Magenta'
    $lines += 'Write-Host ""'
    $lines += ''
    
    # Create individual variable assignments instead of an array to avoid syntax issues
    $appCounter = 0
    foreach ($app in $SelectedApps) {
        $appCounter++
        # Use very simple string handling
        $cleanName = $app.Name -replace "'", "" -replace '"', ""
        $cleanId = $app.Id -replace "'", "" -replace '"', ""
        $lines += "`$app$appCounter = @{ Name = '$cleanName'; Id = '$cleanId' }"
    }
    
    # Create the app array by adding individual apps
    $lines += ''
    $lines += '$selectedApps = @()'
    for ($i = 1; $i -le $appCounter; $i++) {
        $lines += "`$selectedApps += `$app$i"
    }
    
    # Add the rest of the installation logic
    $lines += ''
    $lines += 'Write-Host "Selected $($selectedApps.Count) apps for installation:" -ForegroundColor Yellow'
    $lines += 'foreach ($app in $selectedApps) {'
    $lines += '    Write-Host "  - $($app.Name)" -ForegroundColor Cyan'
    $lines += '}'
    $lines += 'Write-Host ""'
    $lines += ''
    
    # WinGet availability check
    $lines += 'Write-Host "Checking winget availability..." -ForegroundColor Cyan'
    $lines += 'try {'
    $lines += '    $wingetVersion = winget --version 2>$null'
    $lines += '    if ($wingetVersion) {'
    $lines += '        Write-Host "Winget version: $wingetVersion" -ForegroundColor Green'
    $lines += '    } else {'
    $lines += '        throw "Winget not found"'
    $lines += '    }'
    $lines += '} catch {'
    $lines += '    Write-Host "ERROR: Winget is not installed" -ForegroundColor Red'
    $lines += '    exit 1'
    $lines += '}'
    $lines += ''
    
    # Update sources
    $lines += 'Write-Host "Updating winget sources..." -ForegroundColor Cyan'
    $lines += 'winget source update --disable-interactivity'
    $lines += 'Write-Host "Installing Selected Apps..." -ForegroundColor Cyan'
    $lines += 'Write-Host "======================================" -ForegroundColor Gray'
    $lines += ''
    
    # Installation logic
    $lines += '$successCount = 0'
    $lines += '$failCount = 0'
    $lines += '$skippedCount = 0'
    $lines += ''
    $lines += 'foreach ($app in $selectedApps) {'
    $lines += '    $appName = $app.Name'
    $lines += '    $appId = $app.Id'
    $lines += '    Write-Host ""'
    $lines += '    Write-Host "Processing: $appName" -ForegroundColor White'
    $lines += '    Write-Host "Package ID: $appId" -ForegroundColor Gray'
    $lines += '    Write-Host "Checking installation status..." -ForegroundColor Cyan'
    $lines += '    $checkResult = winget list --id $appId --exact --disable-interactivity 2>$null'
    $lines += '    if ($checkResult -and ($checkResult | Select-String -Pattern $appId -Quiet)) {'
    $lines += '        Write-Host "Already installed - skipping" -ForegroundColor Green'
    $lines += '        $skippedCount++'
    $lines += '        continue'
    $lines += '    }'
    $lines += '    Write-Host "Installing $appName..." -ForegroundColor Yellow'
    $lines += '    $process = Start-Process -FilePath "winget" -ArgumentList @("install", "--id", $appId, "--silent", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity") -Wait -PassThru -NoNewWindow'
    $lines += '    if ($process.ExitCode -eq 0) {'
    $lines += '        Write-Host "Successfully installed!" -ForegroundColor Green'
    $lines += '        $successCount++'
    $lines += '    } else {'
    $lines += '        Write-Host "Installation failed" -ForegroundColor Red'
    $lines += '        $failCount++'
    $lines += '    }'
    $lines += '}'
    $lines += ''
    $lines += 'Write-Host "======================================" -ForegroundColor Gray'
    $lines += 'Write-Host "Installation Summary:" -ForegroundColor Magenta'
    $lines += 'Write-Host "Successfully installed: $successCount apps" -ForegroundColor Green'
    $lines += 'Write-Host "Already installed: $skippedCount apps" -ForegroundColor Yellow'
    $lines += 'Write-Host "Failed installations: $failCount apps" -ForegroundColor Red'
    $lines += 'Write-Host "All apps processing completed!" -ForegroundColor Magenta'
    
    # Join all lines
    $wrapperScript = $lines -join "`r`n"
    
    # Create temporary script file
    $tempWrapperFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $wrapperScript | Out-File -FilePath $tempWrapperFile -Encoding UTF8
    
    # Execute the script asynchronously
    try {
        # Clear the right panel and show real-time installation UI
        $rightPanelBorder = $global:window.FindName('RightPanelDesc')
        if ($rightPanelBorder -and $rightPanelBorder.Child) {
            $scrollViewer = $rightPanelBorder.Child
            if ($scrollViewer -and $scrollViewer.Content) {
                $rightPanelStack = $scrollViewer.Content
                $rightPanelStack.Children.Clear()
                
                # Add title
                $titleBlock = New-Object System.Windows.Controls.TextBlock
                $titleBlock.Text = "Installing Selected Apps ($($SelectedApps.Count) apps)"
                $titleBlock.FontSize = 20
                $titleBlock.FontWeight = 'Bold'
                $titleBlock.Foreground = '#FF6F00'
                $titleBlock.FontFamily = 'Segoe UI'
                $titleBlock.Margin = '0,0,0,16'
                $rightPanelStack.Children.Add($titleBlock)
                
                # Add status message
                $statusBlock = New-Object System.Windows.Controls.TextBlock
                $statusBlock.Text = 'Starting installation...'
                $statusBlock.FontSize = 16
                $statusBlock.Foreground = '#03DAC6'
                $statusBlock.FontFamily = 'Segoe UI'
                $statusBlock.Margin = '0,0,0,12'
                $rightPanelStack.Children.Add($statusBlock)
                
                # Add progress container
                $progressBorder = New-Object System.Windows.Controls.Border
                $progressBorder.Background = '#FF1E1E1E'
                $progressBorder.BorderBrush = '#FF3F3F46'
                $progressBorder.BorderThickness = '1'
                $progressBorder.CornerRadius = '4'
                $progressBorder.Margin = '0,12,0,12'
                $progressBorder.Padding = '12'
                
                $progressStack = New-Object System.Windows.Controls.StackPanel
                $progressStack.Orientation = 'Vertical'
                $progressBorder.Child = $progressStack
                $rightPanelStack.Children.Add($progressBorder)
                
                # Start installation in background job
                $installJob = Start-Job -ScriptBlock {
                    param($scriptPath)
                    & powershell -ExecutionPolicy Bypass -File $scriptPath 2>&1
                } -ArgumentList $tempWrapperFile
                
                # Store job ID and references for the timer
                $global:CurrentInstallJobId = $installJob.Id
                $global:InstallStatusBlock = $statusBlock
                $global:InstallProgressStack = $progressStack
                
                # Create timer to monitor progress
                $timer = New-Object System.Windows.Threading.DispatcherTimer
                $timer.Interval = [TimeSpan]::FromSeconds(1)
                $timer.Add_Tick({
                    try {
                        if ($global:CurrentInstallJobId) {
                            $job = Get-Job -Id $global:CurrentInstallJobId -ErrorAction SilentlyContinue
                            if ($job) {
                                if ($job.State -eq 'Completed') {
                                    # Job finished - get results
                                    $results = Receive-Job -Job $job
                                    Remove-Job -Job $job
                                    
                                    # Update status
                                    if ($global:InstallStatusBlock) {
                                        $global:InstallStatusBlock.Text = 'Installation completed!'
                                        $global:InstallStatusBlock.Foreground = '#4CAF50'
                                    }
                                    
                                    # Clear progress and show results
                                    if ($global:InstallProgressStack) {
                                        $global:InstallProgressStack.Children.Clear()
                                        
                                        foreach ($line in $results) {
                                            if ($line -and $line.ToString().Trim() -ne "") {
                                                $outputLine = New-Object System.Windows.Controls.TextBlock
                                                $outputLine.Text = $line.ToString()
                                                $outputLine.FontSize = 12
                                                $outputLine.FontFamily = 'Consolas'
                                                $outputLine.TextWrapping = 'Wrap'
                                                $outputLine.Margin = '0,0,0,2'
                                                
                                                # Color code based on content
                                                if ($line -match "ERROR|FAILED|Exception") {
                                                    $outputLine.Foreground = '#FF6B6B'
                                                } elseif ($line -match "SUCCESS|Successfully|Complete") {
                                                    $outputLine.Foreground = '#4CAF50'
                                                } elseif ($line -match "Installing|Processing") {
                                                    $outputLine.Foreground = '#03DAC6'
                                                } elseif ($line -match "Already installed") {
                                                    $outputLine.Foreground = '#FFC107'
                                                } else {
                                                    $outputLine.Foreground = 'White'
                                                }
                                                
                                                $global:InstallProgressStack.Children.Add($outputLine)
                                            }
                                        }
                                    }
                                    
                                    # Stop timer and cleanup
                                    $this.Stop()
                                    Remove-Item $tempWrapperFile -Force -ErrorAction SilentlyContinue
                                    $global:CurrentInstallJobId = $null
                                    
                                } elseif ($job.State -eq 'Failed') {
                                    # Job failed
                                    $jobError = Receive-Job -Job $job -ErrorAction SilentlyContinue
                                    Remove-Job -Job $job
                                    
                                    if ($global:InstallStatusBlock) {
                                        $global:InstallStatusBlock.Text = 'Installation failed!'
                                        $global:InstallStatusBlock.Foreground = '#FF6B6B'
                                    }
                                    
                                    if ($global:InstallProgressStack) {
                                        $errorLine = New-Object System.Windows.Controls.TextBlock
                                        $errorLine.Text = "Error: $jobError"
                                        $errorLine.FontSize = 12
                                        $errorLine.Foreground = '#FF6B6B'
                                        $errorLine.FontFamily = 'Consolas'
                                        $errorLine.TextWrapping = 'Wrap'
                                        $global:InstallProgressStack.Children.Add($errorLine)
                                    }
                                    
                                    # Stop timer and cleanup
                                    $this.Stop()
                                    Remove-Item $tempWrapperFile -Force -ErrorAction SilentlyContinue
                                    $global:CurrentInstallJobId = $null
                                } else {
                                    # Job still running - update status
                                    if ($global:InstallStatusBlock) {
                                        $global:InstallStatusBlock.Text = 'Installation in progress...'
                                        $global:InstallStatusBlock.Foreground = '#FFEB3B'
                                    }
                                    
                                    # Show a simple progress indicator
                                    if ($global:InstallProgressStack) {
                                        $dots = "." * (([DateTime]::Now.Second % 4) + 1)
                                        $progressLine = New-Object System.Windows.Controls.TextBlock
                                        $progressLine.Text = "Working$dots"
                                        $progressLine.FontSize = 14
                                        $progressLine.Foreground = '#03DAC6'
                                        $progressLine.FontFamily = 'Segoe UI'
                                        $progressLine.Margin = '0,4,0,0'
                                        
                                        $global:InstallProgressStack.Children.Clear()
                                        $global:InstallProgressStack.Children.Add($progressLine)
                                    }
                                }
                            } else {
                                # Job not found - probably completed and cleaned up
                                if ($global:InstallStatusBlock) {
                                    $global:InstallStatusBlock.Text = 'Installation process completed'
                                    $global:InstallStatusBlock.Foreground = '#4CAF50'
                                }
                                $this.Stop()
                                $global:CurrentInstallJobId = $null
                            }
                        } else {
                            # No job ID - stop timer
                            $this.Stop()
                        }
                    } catch {
                        # Error in timer - stop it to prevent spam
                        $this.Stop()
                        $global:CurrentInstallJobId = $null
                    }
                })
                
                # Start the timer
                $timer.Start()
            }
        }
        
    } catch {
        $rightPanelBorder = $global:window.FindName('RightPanelDesc')
        if ($rightPanelBorder -and $rightPanelBorder.Child) {
            $scrollViewer = $rightPanelBorder.Child
            if ($scrollViewer -and $scrollViewer.Content) {
                $rightPanelStack = $scrollViewer.Content
                $rightPanelStack.Children.Clear()
                $errorBlock = New-Object System.Windows.Controls.TextBlock
                $errorBlock.Text = "[ERROR] Failed to start installation: $($_.Exception.Message)"
                $errorBlock.FontSize = 16
                $errorBlock.Foreground = '#FF6B6B'
                $errorBlock.FontFamily = 'Segoe UI'
                $errorBlock.TextWrapping = 'Wrap'
                $rightPanelStack.Children.Add($errorBlock)
            }
        }
        Remove-Item $tempWrapperFile -Force -ErrorAction SilentlyContinue
    }
}

# Add close button event handler
$closeBtn = $global:window.FindName('CloseBtn')
if ($closeBtn) {
    $closeBtn.Add_Click({ $global:window.Close() })
}

# Add maximize button event handler
$maxBtn = $global:window.FindName('MaxBtn')
if ($maxBtn) {
    $maxBtn.Add_Click({
        if ($global:window.WindowState -eq 'Normal') {
            $global:window.WindowState = 'Maximized'
        } else {
            $global:window.WindowState = 'Normal'
        }
    })
}

# Add drag functionality to the custom title bar
$titleBar = $global:window.FindName('TitleBar')
if ($titleBar) {
    $titleBar.Add_MouseLeftButtonDown({
        $global:window.DragMove()
    })
}

# Load and set the logo image from GitHub
$logoImage = $global:window.FindName('LogoImage')
if ($logoImage) {
    try {
        # Try to download logo from GitHub
        $logoUrl = Get-GitHubFileUrl "Files/S_Logo.png"
        
        # Test if the logo exists first
        $response = Invoke-WebRequest -Uri $logoUrl -Method Head -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            # Use Invoke-RestMethod to download the image as bytes
            $imageBytes = Invoke-RestMethod -Uri $logoUrl -Method Get -ContentType "application/octet-stream"
            
            # Convert to byte array if needed
            if ($imageBytes -is [string]) {
                $imageBytes = [System.Text.Encoding]::Latin1.GetBytes($imageBytes)
            }
            
            # Create bitmap from byte array
            $memoryStream = New-Object System.IO.MemoryStream($imageBytes)
            $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
            $bitmap.BeginInit()
            $bitmap.StreamSource = $memoryStream
            $bitmap.DecodePixelWidth = 90   # Higher resolution for better quality
            $bitmap.DecodePixelHeight = 70
            $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bitmap.EndInit()
            $bitmap.Freeze()  # Make it cross-thread accessible
            
            $logoImage.Source = $bitmap
            $logoImage.Stretch = 'Uniform'  # Maintain aspect ratio
            
            # Clean up
            $memoryStream.Dispose()
            
            Write-Host "Logo loaded successfully from GitHub" -ForegroundColor Green
        } else {
            throw "Logo file not found (HTTP $($response.StatusCode))"
        }
    } catch {
        # If logo loading fails, hide the logo and continue gracefully
        Write-Host "Could not load logo from GitHub: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Note: Make sure 'Files/S_Logo.png' exists in your GitHub repository" -ForegroundColor Yellow
        
        # Hide the logo image element if loading fails
        $logoImage.Visibility = 'Collapsed'
        
        # Optionally, you could set a default text or icon here
        # For now, we'll just continue without the logo
    }
}

# Add mouse click functionality to initial menu
$leftPanelBorder = $global:window.FindName('LeftPanelMenu')
if ($leftPanelBorder -and $leftPanelBorder.Child) {
    $leftPanelStack = $leftPanelBorder.Child
    # Find menu items by their text
    $menuItems = $leftPanelStack.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] -and $_.Text -match '^[1-3]\. ' }
    foreach ($item in $menuItems) {
        $item.Cursor = [System.Windows.Input.Cursors]::Hand
        $itemText = $item.Text  # Capture the text value
        $item.Add_MouseLeftButtonUp({
            switch ($itemText) {
                '1. General Tweaks' {
                    global:Show-GeneralTweaksMenu
                }
                '2. Network' {
                    global:Show-NetworkMenu
                }
                '3. Device Info' {
                    global:Show-HardwareMenu
                }
            }
        }.GetNewClosure())  # Create a new closure to capture variables
    }
}

# Initialize the main menu
Show-MainMenu

# Auto-run functionality for elevated restart
if ($AutoRun -eq "Lanman") {
    # Automatically navigate to Network menu and execute Lanman script
    try {
        global:Show-NetworkMenu
        global:Show-LanmanResults
    } catch {
        Write-Host "Error in auto-run: $($_.Exception.Message)"
    }
}

# Show the window
$global:window.ShowDialog() | Out-Null
