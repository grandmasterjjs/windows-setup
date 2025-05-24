# install-dev-machine.ps1

# Set Execution Policy
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Enable Developer Mode
Install-WindowsDeveloperMode

# Install Chocolatey Packages
choco install git vscode firefox powertoys windows-terminal `
    oh-my-posh adguard 1password msteams office365 `
    powershell-core -y

# Install WSL1 and Ubuntu
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
choco install wsl-ubuntu-2204 -y

# Set Windows Appearance to Dark Mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0

# Set Git Global Config
git config --global user.name "J.J. Smiley"
git config --global user.email "jj@grandmasterj.com"

# Configure oh-my-posh theme
$ompPath = "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes"
New-Item -Path $ompPath -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/kali.omp.json" -OutFile "$ompPath\kali.omp.json"

# Install profile

cp $PSScriptRoot\profile\profile.ps1 $PROFILE