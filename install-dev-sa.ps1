<#
install-dev-sa.ps1
JJ Smiley
2025-05-22

This is a "Standalone" (hence -sa) PowerShell config script for setting up my 
development environment. It installs various applications, configures
system settings, and customizes the appearance of Windows.

This script is based on the "install-dev-machine.ps1" script, but this does not
include any Boxstarter commands or environment checks.

This script also checks to see if we're running on a VM.
If we are, it skips the WSL/Ubuntu installation. Since that shit don't work on a VM. ;-)
#>

# Install Chocolatey Packages
choco install git vscode firefox powertoys windows-terminal `
    oh-my-posh adguard 1password msteams office365 `
    powershell-core -y --no-progress

# If we're running on a VM, skip WSL installation
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters") {
    Write-Host "Skipping WSL installation on VM"
    return
}
# Install WSL2 and the latest Ubuntu only if we're not running on a VM
# Install Windows Subsystem for Linux (WSL) and Ubuntu
wsl --install --no-distribution
wsl --set-default-version 2
wsl --set-default -d Ubuntu

# Enable .NET Framework 3.5 (some dev tools require it)
Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart

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