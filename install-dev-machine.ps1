# install-dev-machine.ps1

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

# Install WSL1 and Ubuntu
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
choco install wsl-ubuntu-2204 -y --no-progress

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