# install-dev-machine.ps1

# This script is designed to set up a development machine with essential tools and configurations.
# It installs Chocolatey, various applications, and configures system settings.
# It also sets up Windows Subsystem for Linux (WSL) and Ubuntu, and customizes the appearance of Windows.

# Some of the commands below only run if we're using boxstarter. If running from a normal PowerShell session,
# we need to ensure that Boxstarter is installed and available.

# Check if Boxstarter is installed
if (-not (Get-Command "Boxstarter" -ErrorAction SilentlyContinue)) {
    # Install Boxstarter if not installed
    iex ((New-Object System.Net.WebClient).DownloadString('https://boxstarter.org/bootstrapper.ps1'))
}
# Import Boxstarter module
Import-Module Boxstarter

# Set Boxstarter to use the default Chocolatey source
Set-BoxstarterSource -Default

# Ensure Windows is fully updated before proceeding
Update-Boxstarter -Force

# Prevent sleep during installation
Disable-Sleep

# Enable Developer Mode
Install-WindowsDeveloperMode

# Install Chocolatey Packages
choco install git vscode firefox powertoys windows-terminal `
    oh-my-posh adguard 1password msteams office365 `
    powershell-core -y --no-progress

# Install WSL2 and the latest Ubuntu only if we're not running on a VM
if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters")) {
    # Install WSL2
    wsl --install --no-distribution

    # Install Ubuntu
    wsl --install -d Ubuntu
}
# Install Windows Subsystem for Linux (WSL) and Ubuntu
# Install Windows Terminal and set it as default terminal
wsl --set-default-version 2
wsl --set-default Ubuntu

# Enable .NET Framework 3.5 (some dev tools require it)
Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart

# Pin commonly used apps to the taskbar
Pin-App "Visual Studio Code"
Pin-App "Windows Terminal"
Pin-App "Microsoft Outlook"
Pin-App "Microsoft Teams"

# Set Windows Appearance to Dark Mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    -Name "AppsUseLightTheme" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    -Name "SystemUsesLightTheme" -Value 0 -Force

# Set Git Global Config (ensure git is in PATH)
& "$env:ProgramFiles\Git\bin\git.exe" config --global user.name "J.J. Smiley"
& "$env:ProgramFiles\Git\bin\git.exe" config --global user.email "jj@grandmasterj.com"

# Install profile
if (!(Test-Path -Path (Split-Path -Parent $PROFILE))) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $PROFILE) -Force
}
Copy-Item "$PSScriptRoot\profile\profile.ps1" $PROFILE -Force

# Reboot if required by any previous operation
If (Test-PendingReboot) { Invoke-Reboot }