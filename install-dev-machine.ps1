$GitName = "J.J. Smiley"
$GitEmail = "jj@grandmasterj.com"
$LogFile = "$PSScriptRoot\install-dev-machine.log"

# install-dev-machine.ps1

# This script is designed to set up a development machine with essential tools and configurations.
# It installs Chocolatey, various applications, and configures system settings.
# It also sets up Windows Subsystem for Linux (WSL) and Ubuntu, and customizes the appearance of Windows.

# Some of the commands below only run if we're using boxstarter. If running from a normal PowerShell session,
# we need to ensure that Boxstarter is installed and available.

# If we're running from the Boxstarter "install direct from the web" we do not need to install Boxstarter.

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp $Message"
    Add-Content -Path $LogFile -Value $entry
}

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator."
    exit 1
}

# Enable Developer Mode
Install-WindowsDeveloperMode

# Install Chocolatey Packages
try {
    choco upgrade git vscode firefox powertoys windows-terminal `
        oh-my-posh adguard 1password msteams office365 `
        powershell-core -y --no-progress --install
}
catch {
    Write-Warning "Failed to install Chocolatey packages: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to install Chocolatey packages: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to install Chocolatey packages: $($_ | Out-String)"
}

# Install WSL2 and the latest Ubuntu only if we're not running on a VM
try {
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters")) {
        # Install WSL2
        wsl --install --no-distribution
    
        # Install Ubuntu
        wsl --install -d Ubuntu
    
        # Set WSL defaults
        wsl --set-default-version 2
        wsl --set-default Ubuntu
    }
}
catch {
    Write-Warning "Failed to install WSL/Ubuntu: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to install WSL/Ubuntu: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to install WSL/Ubuntu: $($_ | Out-String)"
}

try {
    # Enable .NET Framework 3.5 (some dev tools require it)
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart
}
catch {
    Write-Warning "Failed to enable .NET Framework 3.5: $($_.Exception.Message)"
}

try {
    if ($env:Boxstarter -eq "true") {
        Pin-App "Visual Studio Code"
        Pin-App "Windows Terminal"
        Pin-App "Microsoft Outlook"
        Pin-App "Microsoft Teams"
    }
}
catch {
    Write-Warning "Failed to pin applications: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to pin applications: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to pin applications: $($_ | Out-String)"
}

# Set Windows Appearance to Dark Mode
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "AppsUseLightTheme" -Value 0 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "SystemUsesLightTheme" -Value 0 -Force
}
catch {
    Write-Warning "Failed to set Windows appearance to dark mode: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to set Windows appearance to dark mode: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to set Windows appearance to dark mode: $($_ | Out-String)"
}

# Set Git Global Config (ensure git is in PATH)
$gitPath = (Get-Command git.exe).Source
& $gitPath config --global user.name $GitName
& $gitPath config --global user.email $GitEmail

# Install profile
try {
if (Test-Path $PROFILE) {
    Copy-Item $PROFILE "$PROFILE.bak" -Force
}
Copy-Item "$PSScriptRoot\profile\profile.ps1" $PROFILE -Force
} catch {
    Write-Warning "Failed to copy profile: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to copy profile: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to copy profile: $($_ | Out-String)"
}

<#
Please note: I hate the "Gallery" module in the Windows 11
sidebar. When I'm running a dev/test machine, I have absolutely
no use for it. So the block below gets rid of this crap
for me.

Your mileage may vary; use at your own risk.
#>
# Remove "Gallery" from File Explorer Sidebar
try {
    $galleryCLSID = "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    $galleryRegPath = "HKCU:\Software\Classes\CLSID\$galleryCLSID"

    # Create the key if it doesn't exist
    if (-not (Test-Path $galleryRegPath)) {
        New-Item -Path $galleryRegPath -Force | Out-Null
    }

    # Set the property to hide it from navigation pane
    New-ItemProperty -Path $galleryRegPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -PropertyType DWORD -Force | Out-Null

    Write-Log "Successfully removed 'Gallery' from File Explorer sidebar."
} catch {
    Write-Warning "Failed to remove 'Gallery' from File Explorer sidebar: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to remove 'Gallery' from sidebar: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to remove 'Gallery' from sidebar: $($_ | Out-String)"
}

if (Test-PendingReboot) {
    Write-Warning "A reboot is required. Please restart manually if not running under Boxstarter."
}

Write-Host ""
Write-Host "`nSetup complete. You may need to restart your computer to apply all changes." -ForegroundColor Green
